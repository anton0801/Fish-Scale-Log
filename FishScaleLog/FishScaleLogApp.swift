import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

@main
struct FishScaleLogApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}

struct SetupConfig {
    static let flyerProgramId = "6757082634"
    static let flyerAuthKey = "XRAvU73MakDNxA4JFj6Wc7"
}

extension AppDelegate {
    
    func tokenUpdates(_ token: String) {
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.set(token, forKey: "push_token")
    }
    
    func startAppDelegateUpdates() {
        delegateAppScaleMergeTimer?.invalidate()
        delegateAppScaleMergeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.sendAllCombinedData()
        }
    }
    
    func handleLaunchNotifications(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let notificationInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            retriveNotificationNeededData(notificationInfo)
        }
    }
    
    func sendAllCombinedData() {
        var mergedData = dataOfAppScaleLog
        for (key, value) in scaleLogAppDeeps {
            if mergedData[key] == nil {
                mergedData[key] = value
            }
        }
        sendData(data: mergedData)
        UserDefaults.standard.set(true, forKey: timerScaleKey)
    }
    
    
    func sendData(data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
}
