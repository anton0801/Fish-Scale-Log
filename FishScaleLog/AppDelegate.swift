import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    var dataOfAppScaleLog: [AnyHashable: Any] = [:]
    
    var delegateAppScaleMergeTimer: Timer?
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    var scaleLogAppDeeps: [AnyHashable: Any] = [:]
    let timerScaleKey = "trackingDataSent"
    
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let deeplinkObject = result.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: timerScaleKey) else { return }
        
        scaleLogAppDeeps = deeplinkObject.clickEvent
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": scaleLogAppDeeps])
        delegateAppScaleMergeTimer?.invalidate()
        
        if !dataOfAppScaleLog.isEmpty {
            sendAllCombinedData()
        }
    }
    
    @objc private func startTracking() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }
    
    private func confugDelegates() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        confugDelegates()
        UIApplication.shared.registerForRemoteNotifications()
        handleLaunchNotifications(launchOptions: launchOptions)
        AppsFlyerLib.shared().appsFlyerDevKey = SetupConfig.flyerAuthKey
        AppsFlyerLib.shared().appleAppID = SetupConfig.flyerProgramId
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        return true
    }
    
    func onConversionDataFail(_ error: Error) {
        sendData(data: [:])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        retriveNotificationNeededData(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        retriveNotificationNeededData(userInfo)
        completionHandler(.newData)
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        dataOfAppScaleLog = data
        startAppDelegateUpdates()
        if !scaleLogAppDeeps.isEmpty {
            sendAllCombinedData()
        }
    }
    
    func retriveNotificationNeededData(_ info: [AnyHashable: Any]) {
        let extractHandler = PushDataExtractor()
        if let urlString = extractHandler.extract(info: info) {
            UserDefaults.standard.set(urlString, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": urlString]
                )
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { [weak self] token, error in
            guard error == nil, let activeToken = token else { return }
            self?.tokenUpdates(activeToken)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let infoPayload = notification.request.content.userInfo
        retriveNotificationNeededData(infoPayload)
        completionHandler([.banner, .sound])
    }
    
    
}
