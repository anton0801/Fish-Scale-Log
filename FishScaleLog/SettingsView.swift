import SwiftUI
import WebKit
import Combine

class ResourcePresenter: ResourcePresenterProtocol {
    @Published var activeResource: URL? = nil
    
    private let interactor: ResourceInteractorProtocol
    
    init(interactor: ResourceInteractorProtocol) {
        self.interactor = interactor
    }
    
    func initializeResource() {
        let startup = interactor.retrieveStartupAddress()
        let stored = interactor.retrieveStoredAddress() ?? ""
        let addressString = startup ?? stored
        
        if let address = URL(string: addressString), !addressString.isEmpty {
            activeResource = address
        }
        
        if startup != nil {
            interactor.eraseStartupAddress()
        }
    }
    
    func updateResource() {
        if let startup = interactor.retrieveStartupAddress(), !startup.isEmpty {
            activeResource = nil
            if let address = URL(string: startup) {
                activeResource = address
            }
            interactor.eraseStartupAddress()
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @State private var showExport = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences").font(.headline)) {
                    Picker("Units", selection: $viewModel.preferredUnit) {
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Data").font(.headline)) {
                    Button("Reset Data", role: .destructive) {
                        viewModel.resetData()
                    }
                }
                
                Section(header: Text("Achievements").font(.title2.bold()).foregroundColor(.white).padding(.top, 20)) {
                    ForEach(viewModel.achievements) { ach in
                        AchievementCard(achievement: ach)
                    }
                }
                
                Section(header: Text("About").font(.headline)) {
                    Text("Fish Scale Log v2.0")
                    Button("Privacy Policy") { UIApplication.shared.open(URL(string: "https://fishscalelog.com/privacy-policy.html")!)}
                }
            }
            .navigationTitle("Settings")
            .background(Color.gray.opacity(0.1))
        }
    }
}


// View
struct PrimaryResourceView: View {
    @StateObject private var presenter: ResourcePresenter
    private let router: ResourceRouterProtocol
    
    init(presenter: ResourcePresenter = ResourcePresenter(interactor: ResourceInteractor()), router: ResourceRouterProtocol = ResourceRouter()) {
        _presenter = StateObject(wrappedValue: presenter)
        self.router = router
    }
    
    var body: some View {
        ZStack {
            if let address = presenter.activeResource {
                ResourceDisplayWrapper(address: address, router: router)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            presenter.initializeResource()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in
            presenter.updateResource()
        }
    }
}


// Resource Display Wrapper
struct ResourceDisplayWrapper: UIViewRepresentable {
    let address: URL
    let router: ResourceRouterProtocol
    
    @StateObject private var displayManager = ResourceDisplayManager()
    
    func makeCoordinator() -> ResourceNavigationHandler {
        ResourceNavigationHandler(manager: displayManager, router: router)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WebConfigBuilder()
            .enableInlinePlayback()
            .setPreferences()
            .setPagePreferences()
            .build()
        
        displayManager.webDisplay = WKWebView(frame: .zero, configuration: config)
        
        WebViewSettingsBuilder(webView: displayManager.webDisplay)
            .disableZoom()
            .disableBounces()
            .enableNavigationGestures()
            .apply()
        
        displayManager.webDisplay.uiDelegate = context.coordinator
        displayManager.webDisplay.navigationDelegate = context.coordinator
        
        displayManager.cookieManager.fetchAndAssignCookies(to: displayManager.webDisplay)
        displayManager.webDisplay.load(URLRequest(url: address))
        
        return displayManager.webDisplay
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class ResourceDisplayManager: ObservableObject {
    @Published var webDisplay: WKWebView!
    @Published var overlayDisplays: [WKWebView] = []
    
    let cookieManager = CookieManager()
    
    func stepBack(to address: URL? = nil) {
        if !overlayDisplays.isEmpty {
            if let finalOverlay = overlayDisplays.last {
                finalOverlay.removeFromSuperview()
                overlayDisplays.removeLast()
            }
            
            if let targetAddress = address {
                webDisplay.load(URLRequest(url: targetAddress))
            }
        } else if webDisplay.canGoBack {
            webDisplay.goBack()
        }
    }
    
    func refreshDisplay() {
        webDisplay.reload()
    }
}

class ResourceNavigationHandler: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let manager: ResourceDisplayManager
    private let router: ResourceRouterProtocol
    private var redirectTracker = 0
    private var previousAddress: URL?
    private let redirectLimit = 70
    
    init(manager: ResourceDisplayManager, router: ResourceRouterProtocol) {
        self.manager = manager
        self.router = router
    }
    
    @objc func processEdgeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended,
              let activeDisplay = gesture.view as? WKWebView else { return }
        
        if activeDisplay.canGoBack {
            activeDisplay.goBack()
        } else if manager.overlayDisplays.last === activeDisplay {
            manager.stepBack(to: nil)
        }
    }
    
    
    private func validateNavigationRequest(_ request: URLRequest) -> Bool {
        guard let addressString = request.url?.absoluteString,
              !addressString.isEmpty,
              addressString != "about:blank" else { return false }
        return true
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let optimizationScript = """
        (function() {
            var viewportMeta = document.createElement('meta');
            viewportMeta.name = 'viewport';
            viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(viewportMeta);
            
            var customStyle = document.createElement('style');
            customStyle.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(customStyle);
            
            document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
            document.addEventListener('gesturechange', function(e) { e.preventDefault(); });
        })();
        """
        webView.evaluateJavaScript(optimizationScript) { _, issue in
            if let issue = issue {
                print("Script evaluation issue: \(issue)")
            }
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorHTTPTooManyRedirects,
           let fallbackAddress = previousAddress {
            webView.load(URLRequest(url: fallbackAddress))
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let overlayDisplay = WKWebView(frame: .zero, configuration: configuration)
        
        let settingsBuilder = WebViewSettingsBuilder(webView: overlayDisplay)
            .disableZoom()
            .disableBounces()
            .enableNavigationGestures()
        overlayDisplay.scrollView.isScrollEnabled = true
        settingsBuilder.apply()
        
        overlayDisplay.translatesAutoresizingMaskIntoConstraints = false
        overlayDisplay.navigationDelegate = self
        overlayDisplay.uiDelegate = self
        manager.webDisplay.addSubview(overlayDisplay)
        
        NSLayoutConstraint.activate([
            overlayDisplay.leadingAnchor.constraint(equalTo: manager.webDisplay.leadingAnchor),
            overlayDisplay.trailingAnchor.constraint(equalTo: manager.webDisplay.trailingAnchor),
            overlayDisplay.topAnchor.constraint(equalTo: manager.webDisplay.topAnchor),
            overlayDisplay.bottomAnchor.constraint(equalTo: manager.webDisplay.bottomAnchor)
        ])
        
        manager.overlayDisplays.append(overlayDisplay)
        
        let gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processEdgeGesture))
        gestureRecognizer.edges = .left
        overlayDisplay.addGestureRecognizer(gestureRecognizer)
        
        if validateNavigationRequest(navigationAction.request) {
            overlayDisplay.load(navigationAction.request)
        }
        
        return overlayDisplay
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectTracker += 1
        
        if redirectTracker > redirectLimit {
            webView.stopLoading()
            if let fallbackAddress = previousAddress {
                webView.load(URLRequest(url: fallbackAddress))
            }
            return
        }
        
        previousAddress = webView.url
        manager.cookieManager.collectAndPersistCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let targetAddress = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        previousAddress = targetAddress
        let protocolScheme = (targetAddress.scheme ?? "").lowercased()
        let fullPath = targetAddress.absoluteString.lowercased()
        
        let supportedProtocols: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let supportedStarts = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let permitted = supportedProtocols.contains(protocolScheme) ||
                        supportedStarts.contains { fullPath.hasPrefix($0) } ||
                        fullPath == "about:blank"
        
        if permitted {
            decisionHandler(.allow)
        } else {
            router.launchExternalResource(targetAddress)
            decisionHandler(.cancel)
        }
    }
    
}

