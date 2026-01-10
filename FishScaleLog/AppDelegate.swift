import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

class ScaleLogAppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var scaleLogMetrics: [AnyHashable: Any] = [:]
    private var scaleLogEntries: [AnyHashable: Any] = [:]
    private let metricsSentFlag = "metricsDispatched"
    
    private var mergeTimer: Timer?
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        setupProtocolHandlers()
        registerForAlerts()
        processStartupAlerts(launchOptions: launchOptions)
        initializeTrackerLib()
        configureEventListeners()
        return true
    }
    
    private func configureFirebase() {
        FirebaseApp.configure()
    }
    
    private func setupProtocolHandlers() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    private func registerForAlerts() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status else { return }
        guard let entryObject = result.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: metricsSentFlag) else { return }
        
        scaleLogEntries = entryObject.clickEvent
        postEntryNotification()
        invalidateMergeTimer()
        
        if !scaleLogMetrics.isEmpty {
            performDataMergeAndDispatch()
        }
    }
    
    private func postEntryNotification() {
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": scaleLogEntries])
    }
    
    private func invalidateMergeTimer() {
        mergeTimer?.invalidate()
    }
    
    private func initializeTrackerLib() {
        let tracker = AppsFlyerLib.shared()
        tracker.appsFlyerDevKey = SetupConfig.flyerAuthKey
        tracker.appleAppID = SetupConfig.flyerProgramId
        tracker.delegate = self
        tracker.deepLinkDelegate = self
    }
    
    @objc private func initiateTracking() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            requestTrackingAuth()
        }
    }
    
    private func requestTrackingAuth() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                AppsFlyerLib.shared().start()
            }
        }
    }
    
    private func configureEventListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(initiateTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        processAlertPayload(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        processAlertPayload(userInfo)
        completionHandler(.newData)
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        scaleLogMetrics = data
        initiateMergeProcess()
        checkAndMergeEntries()
    }
    
    private func checkAndMergeEntries() {
        if !scaleLogEntries.isEmpty {
            performDataMergeAndDispatch()
        }
    }
    
    func onConversionDataFail(_ error: Error) {
        dispatchEmptyData()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        fetchAndUpdateToken(messaging)
    }
    
    private func fetchAndUpdateToken(_ messaging: Messaging) {
        messaging.token { [weak self] token, error in
            guard error == nil, let validToken = token else { return }
            self?.storeToken(validToken)
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payload = notification.request.content.userInfo
        processAlertPayload(payload)
        completionHandler([.banner, .sound])
    }
}

extension ScaleLogAppDelegate {
    
    private func initiateMergeProcess() {
        mergeTimer?.invalidate()
        mergeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.performDataMergeAndDispatch()
        }
    }
    
    private func processAlertPayload(_ info: [AnyHashable: Any]) {
        let extractor = PushDataExtractor()
        if let urlString = extractor.analyze(details: info) {
            storeTemporaryURL(urlString)
            scheduleURLNotification(urlString)
        }
    }
    
    private func storeTemporaryURL(_ urlString: String) {
        UserDefaults.standard.set(urlString, forKey: "temp_url")
    }
    
    private func scheduleURLNotification(_ urlString: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NotificationCenter.default.post(
                name: NSNotification.Name("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": urlString]
            )
        }
    }
    
    func processStartupAlerts(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let notificationInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            processAlertPayload(notificationInfo)
        }
    }
    
    private func dispatchData(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    private func dispatchEmptyData() {
        dispatchData([:])
    }
    
    private func performDataMergeAndDispatch() {
        var mergedData = scaleLogMetrics
        for (key, value) in scaleLogEntries {
            if mergedData[key] == nil {
                mergedData[key] = value
            }
        }
        dispatchData(mergedData)
        UserDefaults.standard.set(true, forKey: metricsSentFlag)
    }
    
    private func storeToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "fcm_token")
        UserDefaults.standard.set(token, forKey: "push_token")
    }
}

struct PushDataExtractor {
    func analyze(details: [AnyHashable: Any]) -> String? {
        if let uri = details["url"] as? String {
            return uri
        } else if let nestedDetails = details["data"] as? [String: Any],
                  let nestedUri = nestedDetails["url"] as? String {
            return nestedUri
        }
        return nil
    }
}
