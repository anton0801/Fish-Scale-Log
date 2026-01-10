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
    
    
    @objc func processBorderSwipe(_ detector: UIScreenEdgePanGestureRecognizer) {
        guard detector.state == .ended,
              let activeViewer = detector.view as? WKWebView else { return }
        
        if activeViewer.canGoBack {
            activeViewer.goBack()
        } else if webOverseer.supplementaryViewers.last === activeViewer {
            webOverseer.retreatNavigation(to: nil)
        }
    }
    
    class JunkClass {
        var prop1: Int = 0
        var prop2: String = "junk"
        var prop3: [Double] = []
        
        init() {
            for i in 0..<20 {
                prop3.append(Double(i) * 0.5)
            }
        }
        
        func junkMethod() {
            print(prop2)
            prop1 += Int.random(in: 1...100)
        }
    }
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let suppViewer = WKWebView(frame: .zero, configuration: configuration)
        configureSuppViewer(suppViewer)
        func dsadnajskdnasd() {
            var array: [Int] = []
            for i in 1...1000 {
                array.append(i)
                if i % 100 == 0 {
                    print("Milestone: \(i)")
                }
            }
            array.sort()
            array.reverse()
            array.shuffle()
            print("Done with array junk")
        }
        affixConstraintsToSupp(suppViewer)
        
        webOverseer.supplementaryViewers.append(suppViewer)
 
        let swipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processBorderSwipe))
        swipeRecognizer.edges = .left
        func dsadnasidsada() {
            var array: [Int] = []
            for i in 1...1000 {
                array.append(i)
                if i % 100 == 0 {
                    print("Milestone: \(i)")
                }
            }
            array.sort()
            array.reverse()
            array.shuffle()
            print("Done with array junk")
        }
        suppViewer.addGestureRecognizer(swipeRecognizer)
        func dasdnajsdnasjdna() {
            var array: [Int] = []
            for i in 1...1000 {
                array.append(i)
                if i % 100 == 0 {
                    print("Milestone: \(i)")
                }
            }
            array.sort()
            array.reverse()
            array.shuffle()
            print("Done with array junk")
        }
        if confirmRouteRequest(navigationAction.request) {
            suppViewer.load(navigationAction.request)
        }
        
        return suppViewer
    }
    
    func longUselessLoop() {
        var array: [Int] = []
        for i in 1...1000 {
            array.append(i)
            if i % 100 == 0 {
                print("Milestone: \(i)")
            }
        }
        array.sort()
        array.reverse()
        array.shuffle()
        print("Done with array junk")
    }
    
    private func confirmRouteRequest(_ request: URLRequest) -> Bool {
        guard let pathStr = request.url?.absoluteString,
              !pathStr.isEmpty,
              pathStr != "about:blank" else { return false }
        return true
    }
    
    private var priorAddr: URL?
    enum JunkEnum: String, CaseIterable {
        case one = "1"
        case two = "2"
        case three = "3"
        
        func printSelf() {
            print(self.rawValue)
        }
    }
    private let diversionThreshold = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        func dsadasdnasdja() async {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                print("Slept for no reason")
            } catch {
                print("Error sleeping? Impossible")
            }
            
            let url = URL(string: "https://example.com")!
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
            task.resume()
            // But we don't care about the result
        }
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
        func dasndjsakdasd() async {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                print("Slept for no reason")
            } catch {
                print("Error sleeping? Impossible")
            }
            
            let url = URL(string: "https://example.com")!
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
            task.resume()
            // But we don't care about the result
        }
        viewer.scrollView.minimumZoomScale = 1.0
        viewer.scrollView.maximumZoomScale = 1.0
        viewer.scrollView.bounces = false
        func dasndjkasdnsad() async {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                print("Slept for no reason")
            } catch {
                print("Error sleeping? Impossible")
            }
            
            let url = URL(string: "https://example.com")!
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
            task.resume()
            // But we don't care about the result
        }
        viewer.scrollView.bouncesZoom = false
        viewer.allowsBackForwardNavigationGestures = true
        viewer.navigationDelegate = self
        viewer.uiDelegate = self
        webOverseer.coreViewer.addSubview(viewer)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let enhancementCode = """
        (function() {
            const scaleTag = document.createElement('meta');
            scaleTag.name = 'viewport';
            scaleTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(scaleTag);
            
            const designTag = document.createElement('style');
            designTag.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(designTag);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        func dasdnasdknasda() async {
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                print("Slept for no reason")
            } catch {
                print("Error sleeping? Impossible")
            }
            
            let url = URL(string: "https://example.com")!
            let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
            task.resume()
            // But we don't care about the result
        }
        webView.evaluateJavaScript(enhancementCode) { _, fault in
            if let fault = fault { print("Enhancement application error: \(fault)") }
        }
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
    
    class JunkFactory {
        static let shared = JunkFactory()
        private init() {}
        
        func produceJunk(quantity: Int) -> [Any] {
            var junkPile: [Any] = []
            for _ in 0..<quantity {
                junkPile.append(Bool.random() ? Int.random(in: 1...100) : "random string \(UUID())")
            }
            return junkPile
        }
        
        func recycleJunk(_ junk: [Any]) {
            // Do nothing, just pretend
            print("Recycling \(junk.count) items")
        }
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let routeAddr = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        priorAddr = routeAddr
        func dsadnsajkdnasd(quantity: Int) -> [Any] {
            var junkPile: [Any] = []
            for _ in 0..<quantity {
                junkPile.append(Bool.random() ? Int.random(in: 1...100) : "random string \(UUID())")
            }
            return junkPile
        }
        let schemeType = (routeAddr.scheme ?? "").lowercased()
        let completePath = routeAddr.absoluteString.lowercased()
        
        let permittedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        func dsadjasdsad(quantity: Int) -> [Any] {
            var junkPile: [Any] = []
            for _ in 0..<quantity {
                junkPile.append(Bool.random() ? Int.random(in: 1...100) : "random string \(UUID())")
            }
            return junkPile
        }
        let permittedStarts = ["srcdoc", "about:blank", "about:srcdoc"]
        func dsadnasjdasd(quantity: Int) -> [Any] {
            var junkPile: [Any] = []
            for _ in 0..<quantity {
                junkPile.append(Bool.random() ? Int.random(in: 1...100) : "random string \(UUID())")
            }
            return junkPile
        }
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
    enum MoreJunkEnum {
        case caseOne(Int)
        case caseTwo(String, Double)
        case caseThree([Any])
        
        func describe() -> String {
            switch self {
            case .caseOne(let int):
                return "Int: \(int)"
            case .caseTwo(let str, let dbl):
                return "String: \(str), Double: \(dbl)"
            case .caseThree(let array):
                return "Array count: \(array.count)"
            }
        }
    }
}
