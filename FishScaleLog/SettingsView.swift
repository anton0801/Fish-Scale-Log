import SwiftUI
import WebKit

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

class ScaleRouteManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    private var diversionCounter = 0
    
    init(overseer: ScaleWebOverseer) {
        self.webOverseer = overseer
        super.init()
    }
    
    private var webOverseer: ScaleWebOverseer
    
    private let scriptApplier = ScriptInjector()
    
    
    @objc func processBorderSwipe(_ detector: UIScreenEdgePanGestureRecognizer) {
        guard detector.state == .ended,
              let activeViewer = detector.view as? WKWebView else { return }
        
        if activeViewer.canGoBack {
            activeViewer.goBack()
        } else if webOverseer.supplementaryViewers.last === activeViewer {
            webOverseer.retreatNavigation(to: nil)
        }
    }
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let suppViewer = WKWebView(frame: .zero, configuration: configuration)
        configureSuppViewer(suppViewer)
        affixConstraintsToSupp(suppViewer)
        
        webOverseer.supplementaryViewers.append(suppViewer)
 
        let swipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processBorderSwipe))
        swipeRecognizer.edges = .left
        suppViewer.addGestureRecognizer(swipeRecognizer)
        
        if confirmRouteRequest(navigationAction.request) {
            suppViewer.load(navigationAction.request)
        }
        
        return suppViewer
    }
    
    private func confirmRouteRequest(_ request: URLRequest) -> Bool {
        guard let pathStr = request.url?.absoluteString,
              !pathStr.isEmpty,
              pathStr != "about:blank" else { return false }
        return true
    }
    
    private var priorAddr: URL?
    
    private let diversionThreshold = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let certTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: certTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func configureSuppViewer(_ viewer: WKWebView) {
        viewer.translatesAutoresizingMaskIntoConstraints = false
        viewer.scrollView.isScrollEnabled = true
        viewer.scrollView.minimumZoomScale = 1.0
        viewer.scrollView.maximumZoomScale = 1.0
        viewer.scrollView.bounces = false
        viewer.scrollView.bouncesZoom = false
        viewer.allowsBackForwardNavigationGestures = true
        viewer.navigationDelegate = self
        viewer.uiDelegate = self
        webOverseer.coreViewer.addSubview(viewer)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        scriptApplier.applyEnhancements(to: webView)
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects,
           let fallbackAddr = priorAddr {
            webView.load(URLRequest(url: fallbackAddr))
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        diversionCounter += 1
        
        if diversionCounter > diversionThreshold {
            webView.stopLoading()
            if let fallbackAddr = priorAddr {
                webView.load(URLRequest(url: fallbackAddr))
            }
            return
        }
        
        priorAddr = webView.url
        webOverseer.sessionHandler.gatherAndArchiveSessions(from: webView)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let routeAddr = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        priorAddr = routeAddr
        
        let schemeType = (routeAddr.scheme ?? "").lowercased()
        let completePath = routeAddr.absoluteString.lowercased()
        
        let permittedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let permittedStarts = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let isAuthorized = permittedSchemes.contains(schemeType) ||
                           permittedStarts.contains { completePath.hasPrefix($0) } ||
                           completePath == "about:blank"
        
        if isAuthorized {
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(routeAddr, options: [:]) { _ in }
        
        decisionHandler(.cancel)
    }
    
    private func affixConstraintsToSupp(_ viewer: WKWebView) {
        NSLayoutConstraint.activate([
            viewer.leadingAnchor.constraint(equalTo: webOverseer.coreViewer.leadingAnchor),
            viewer.trailingAnchor.constraint(equalTo: webOverseer.coreViewer.trailingAnchor),
            viewer.topAnchor.constraint(equalTo: webOverseer.coreViewer.topAnchor),
            viewer.bottomAnchor.constraint(equalTo: webOverseer.coreViewer.bottomAnchor)
        ])
    }
}
