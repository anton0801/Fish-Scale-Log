import Foundation
import MapKit
import CoreLocation
import AppsFlyerLib
import WebKit
import Firebase
import FirebaseMessaging


class CookieManager {
    func fetchAndAssignCookies(to browser: WKWebView) {
        guard let archivedCookies = UserDefaults.standard.object(forKey: "archived_cookies") as? [[HTTPCookiePropertyKey: Any]] else { return }
        
        let cookieRepository = browser.configuration.websiteDataStore.httpCookieStore
        
        let restoredCookies = archivedCookies.compactMap { attrs in
            HTTPCookie(properties: attrs)
        }
        
        for cookie in restoredCookies {
            cookieRepository.setCookie(cookie)
        }
    }
    
    func collectAndPersistCookies(from browser: WKWebView) {
        browser.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let cookieAttrs = cookies.compactMap { cookie in
                cookie.properties
            }
            
            UserDefaults.standard.set(cookieAttrs, forKey: "archived_cookies")
        }
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


protocol PermissionRepository {
    func updateFinalConsentTime(_ time: Date)
    func approveConsent(_ approved: Bool)
    func declineConsent(_ declined: Bool)
    func isConsentApproved() -> Bool
    func isConsentDeclined() -> Bool
    func retrieveFinalConsentTime() -> Date?
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

protocol DeviceInfoRepository {
    func retrieveAlertToken() -> String?
    func retrieveLocaleCode() -> String
    func retrievePackageIdentifier() -> String
    func retrieveCloudSender() -> String?
    func retrieveMarketIdentifier() -> String
    func retrieveUniqueTracker() -> String
}

class DeviceInfoRepositoryImpl: DeviceInfoRepository {
    private let flyer = AppsFlyerLib.shared()
    
    func retrieveAlertToken() -> String? {
        UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
    }
    
    func retrieveLocaleCode() -> String {
        Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    func retrievePackageIdentifier() -> String {
        "com.scallelogfish.FishScaleLog"
    }
    
    func retrieveCloudSender() -> String? {
        FirebaseApp.app()?.options.gcmSenderID
    }
    
    func retrieveMarketIdentifier() -> String {
        "id\(SetupConfig.flyerProgramId)"
    }
    
    func retrieveUniqueTracker() -> String {
        flyer.getAppsFlyerUID()
    }
}
