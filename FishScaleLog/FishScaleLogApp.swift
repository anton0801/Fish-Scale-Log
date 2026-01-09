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


class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var dataOfAppScaleLog: [AnyHashable: Any] = [:]
    
    private var delegateAppScaleMergeTimer: Timer?
    private var scaleLogAppDeeps: [AnyHashable: Any] = [:]
    private let timerScaleKey = "trackingDataSent"
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
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
        configObservers()
        return true
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
    
    private func configObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(startTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        retriveNotificationNeededData(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        retriveNotificationNeededData(userInfo)
        completionHandler(.newData)
    }
    
    func onConversionDataFail(_ error: Error) {
        sendData(data: [:])
    }
    
    private func retriveNotificationNeededData(_ info: [AnyHashable: Any]) {
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
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        dataOfAppScaleLog = data
        startAppDelegateUpdates()
        if !scaleLogAppDeeps.isEmpty {
            sendAllCombinedData()
        }
    }
    
}

extension AppDelegate {
    
    func tokenUpdates(_ token: String) {
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.set(token, forKey: "push_token")
    }
    
    private func startAppDelegateUpdates() {
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
    
    private func sendAllCombinedData() {
        var mergedData = dataOfAppScaleLog
        for (key, value) in scaleLogAppDeeps {
            if mergedData[key] == nil {
                mergedData[key] = value
            }
        }
        sendData(data: mergedData)
        UserDefaults.standard.set(true, forKey: timerScaleKey)
    }
    
    
    private func sendData(data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
}
