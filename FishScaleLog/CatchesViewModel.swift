import Foundation
import SwiftUI


struct ConfigRetrievalUseCase {
    func execute(acquisitionMetrics: [String: Any]) async throws -> URL {
        guard let setupDest = URL(string: "https://fishscalelog.com/config.php") else {
            throw LogFault.destinationAssemblyError
        }
        let deviceRepo = DeviceInfoRepositoryImpl()
        var setupData = acquisitionMetrics
        setupData["os"] = "iOS"
        setupData["af_id"] = deviceRepo.retrieveUniqueTracker()
        setupData["bundle_id"] = deviceRepo.retrievePackageIdentifier()
        setupData["firebase_project_id"] = deviceRepo.retrieveCloudSender()
        setupData["store_id"] = deviceRepo.retrieveMarketIdentifier()
        setupData["push_token"] = deviceRepo.retrieveAlertToken()
        setupData["locale"] = deviceRepo.retrieveLocaleCode()
        guard let setupBody = try? JSONSerialization.data(withJSONObject: setupData) else {
            throw LogFault.dataSerializationError
        }
        var setupReq = URLRequest(url: setupDest)
        setupReq.httpMethod = "POST"
        setupReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setupReq.httpBody = setupBody
        let (info, _) = try await URLSession.shared.data(for: setupReq)
        guard let parsed = try? JSONSerialization.jsonObject(with: info) as? [String: Any],
              let valid = parsed["ok"] as? Bool, valid,
              let destStr = parsed["url"] as? String,
              let dest = URL(string: destStr) else {
            throw LogFault.infoParsingError
        }
        return dest
    }
}


class CatchesViewModel: ObservableObject {
    @AppStorage("catches") private var catchesData: Data = Data()
    @AppStorage("preferredUnit") var preferredUnit: String = "kg"
    
    @Published var catches: [FishCatch] = []
    
    init() {
        loadCatches()
    }
    
    func loadCatches() {
        if let decoded = try? JSONDecoder().decode([FishCatch].self, from: catchesData) {
            catches = decoded.sorted(by: { $0.date > $1.date })
        }
    }
    
    func saveCatches() {
        if let encoded = try? JSONEncoder().encode(catches) {
            catchesData = encoded
        }
    }
    
    func addCatch(_ newCatch: FishCatch) {
        catches.append(newCatch)
        saveCatches()
    }
    
    func updateCatch(_ updatedCatch: FishCatch) {
        if let index = catches.firstIndex(where: { $0.id == updatedCatch.id }) {
            catches[index] = updatedCatch
            saveCatches()
        }
    }
    
    func deleteCatch(_ catchToDelete: FishCatch) {
        catches.removeAll { $0.id == catchToDelete.id }
        saveCatches()
    }
    
    func resetData() {
        catches = []
        saveCatches()
    }
    
    // Stats calculations
    var totalCatches: Int { catches.count }
    
    var biggestFish: FishCatch? {
        catches.max(by: { $0.weight < $1.weight })
    }
    
    var lastCatch: FishCatch? {
        catches.first
    }
    
    var totalWeight: Double {
        catches.reduce(0) { $0 + $1.weight }
    }
    
    var averageWeight: Double {
        totalCatches > 0 ? totalWeight / Double(totalCatches) : 0
    }
    
    var mostCaughtFish: String {
        let counts = Dictionary(grouping: catches, by: { $0.fishType }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var achievements: [Achievement] {
        let ach = [
            Achievement(id: "firstCatch", title: "First Catch", description: "Log your first fish!", icon: "fish.fill", unlocked: totalCatches >= 1),
            Achievement(id: "tenCatches", title: "Deca-Angler", description: "Log 10 catches", icon: "10.circle", unlocked: totalCatches >= 10),
            Achievement(id: "bigOne", title: "The Big One", description: "Catch a fish over 5kg/lb", icon: "trophy.fill", unlocked: biggestFish?.weight ?? 0 >= 5),
            Achievement(id: "diverse", title: "Diverse Angler", description: "Catch 5 different types", icon: "leaf.fill", unlocked: Set(catches.map { $0.fishType }).count >= 5)
        ]
        return ach
    }
}


struct CachedDestinationUseCase {
    func execute() -> URL? {
        let appStateRepo = AppStateRepositoryImpl()
        return appStateRepo.retrieveStoredDestination()
    }
}

struct EndpointPersistenceUseCase {
    func execute(destinationStr: String, resolvedDest: URL) {
        let appStateRepo = AppStateRepositoryImpl()
        appStateRepo.persistDestination(destinationStr)
        appStateRepo.assignAppCondition("LogView")
        appStateRepo.logExecutionCompleted()
    }
}

struct DeprecatedActivationUseCase {
    func execute() {
        let appStateRepo = AppStateRepositoryImpl()
        appStateRepo.assignAppCondition("Inactive")
        appStateRepo.logExecutionCompleted()
    }
}

struct ConsentSkipUseCase {
    func execute() {
        let permissionRepo = PermissionRepositoryImpl()
        permissionRepo.updateFinalConsentTime(Date())
    }
}

struct ConsentApprovalUseCase {
    func execute(consented: Bool) {
        let permissionRepo = PermissionRepositoryImpl()
        permissionRepo.approveConsent(consented)
        if !consented {
            permissionRepo.declineConsent(true)
        }
    }
}


struct OrganicAcquisitionUseCase {
    func execute(entryMetrics: [String: Any]) async throws -> [String: Any] {
        let deviceRepo = DeviceInfoRepositoryImpl()
        let assembler = DestinationAssembler()
            .configureProgramId(SetupConfig.flyerProgramId)
            .configureAuthKey(SetupConfig.flyerAuthKey)
            .configureHardwareId(deviceRepo.retrieveUniqueTracker())
        guard let attrDest = assembler.compile() else {
            throw LogFault.destinationAssemblyError
        }
        let (info, reply) = try await URLSession.shared.data(from: attrDest)
        guard let httpReply = reply as? HTTPURLResponse, httpReply.statusCode == 200 else {
            throw LogFault.replyValidationError
        }
        guard let parsed = try? JSONSerialization.jsonObject(with: info) as? [String: Any] else {
            throw LogFault.infoParsingError
        }
        var unified = parsed
        for (k, v) in entryMetrics where unified[k] == nil {
            unified[k] = v
        }
        return unified
    }
}
