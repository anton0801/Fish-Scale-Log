import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

@main
struct FishScaleLogApp: App {
    
    @UIApplicationDelegateAdaptor(ScaleLogAppDelegate.self) var appDelegate
    
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
