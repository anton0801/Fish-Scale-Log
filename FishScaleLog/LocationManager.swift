import Foundation
import MapKit
import CoreLocation

protocol AppStateRepository {
    var isInitialExecution: Bool { get }
    func retrieveStoredDestination() -> URL?
    func persistDestination(_ url: String)
    func assignAppCondition(_ condition: String)
    func logExecutionCompleted()
    func retrieveAppCondition() -> String?
}

class AppStateRepositoryImpl: AppStateRepository {
    private let storage = UserDefaults.standard
    
    var isInitialExecution: Bool {
        !storage.bool(forKey: "executedPreviously")
    }
    
    func retrieveStoredDestination() -> URL? {
        if let str = storage.string(forKey: "persisted_destination"), let url = URL(string: str) {
            return url
        }
        return nil
    }
    
    func persistDestination(_ url: String) {
        storage.set(url, forKey: "persisted_destination")
    }
    
    func assignAppCondition(_ condition: String) {
        storage.set(condition, forKey: "app_condition")
    }
    
    func logExecutionCompleted() {
        storage.set(true, forKey: "executedPreviously")
    }
    
    func retrieveAppCondition() -> String? {
        storage.string(forKey: "app_condition")
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
}

class PermissionRepositoryImpl: PermissionRepository {
    private let storage = UserDefaults.standard
    
    func updateFinalConsentTime(_ time: Date) {
        storage.set(time, forKey: "consent_timestamp")
    }
    
    func approveConsent(_ approved: Bool) {
        storage.set(approved, forKey: "consent_approved")
    }
    
    func declineConsent(_ declined: Bool) {
        storage.set(declined, forKey: "consent_declined")
    }
    
    func isConsentApproved() -> Bool {
        storage.bool(forKey: "consent_approved")
    }
    
    func isConsentDeclined() -> Bool {
        storage.bool(forKey: "consent_declined")
    }
    
    func retrieveFinalConsentTime() -> Date? {
        storage.object(forKey: "consent_timestamp") as? Date
    }
}

struct PhaseEvaluationUseCase {
    func execute(acquisitionMetrics: [String: Any], isInitial: Bool, provisionalUrl: String?) -> LogPhase {
        if acquisitionMetrics.isEmpty {
            return .deprecated
        }
        if UserDefaults.standard.string(forKey: "app_condition") == "Inactive" {
            return .deprecated
        }
        if isInitial && (acquisitionMetrics["af_status"] as? String == "Organic") {
            return .bootstrapping
        }
        if provisionalUrl != nil {
            return .operational
        }
        return .bootstrapping
    }
}

struct ConsentVerificationUseCase {
    func execute() -> Bool {
        let permissionRepo = PermissionRepositoryImpl()
        guard !permissionRepo.isConsentApproved(), !permissionRepo.isConsentDeclined() else {
            return false
        }
        if let prior = permissionRepo.retrieveFinalConsentTime(), Date().timeIntervalSince(prior) < 259200 {
            return false
        }
        return true
    }
}

struct PushDataExtractor {
    func extract(info: [AnyHashable: Any]) -> String? {
        var parsedLink: String?
        if let link = info["url"] as? String {
            parsedLink = link
        } else if let subInfo = info["data"] as? [String: Any],
                  let subLink = subInfo["url"] as? String {
            parsedLink = subLink
        }
        if let activeLink = parsedLink {
            return activeLink
        }
        return nil
    }
}
