import SwiftUI
import WebKit
import Combine

struct HomeView: View {
    @ObservedObject var viewModel: CatchesViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    OverviewCard(title: "Total Catches", value: "\(viewModel.totalCatches)", icon: "list.bullet")
                    if let biggest = viewModel.biggestFish {
                        OverviewCard(title: "Biggest Fish", value: "\(biggest.fishType) - \(biggest.weight) \(biggest.unit)", icon: "trophy.fill")
                    } else {
                        OverviewCard(title: "Biggest Fish", value: "None yet", icon: "trophy.fill")
                    }
                    if let last = viewModel.lastCatch {
                        OverviewCard(title: "Last Catch", value: "\(last.fishType) - \(last.weight) \(last.unit)", icon: "clock.fill")
                    } else {
                        OverviewCard(title: "Last Catch", value: "None yet", icon: "clock.fill")
                    }
                }
                .padding()
            }
            .navigationTitle("Overview")
            .background(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.4), .green.opacity(0.3)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
    }
}


class ScaleWebOverseer: ObservableObject {
    @Published var coreViewer: WKWebView!
    
    private var monitors = Set<AnyCancellable>()
    
    func initCoreViewer() {
        let viewerConfig = buildViewerConfig()
        coreViewer = WKWebView(frame: .zero, configuration: viewerConfig)
        adjustViewerSettings(on: coreViewer)
    }
    
    private func buildViewerConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let configPrefs = WKPreferences()
        configPrefs.javaScriptEnabled = true
        configPrefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = configPrefs
        
        let contentPrefs = WKWebpagePreferences()
        contentPrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = contentPrefs
        
        return config
    }
    
    private func adjustViewerSettings(on viewer: WKWebView) {
        viewer.scrollView.minimumZoomScale = 1.0
        viewer.scrollView.maximumZoomScale = 1.0
        viewer.scrollView.bounces = false
        viewer.scrollView.bouncesZoom = false
        viewer.allowsBackForwardNavigationGestures = true
    }
    
    @Published var supplementaryViewers: [WKWebView] = []
    
    let sessionHandler = SessionHandler()
    
    func retreatNavigation(to addr: URL? = nil) {
        if !supplementaryViewers.isEmpty {
            if let ultimateSupp = supplementaryViewers.last {
                ultimateSupp.removeFromSuperview()
                supplementaryViewers.removeLast()
            }
            
            if let targetAddr = addr {
                coreViewer.load(URLRequest(url: targetAddr))
            }
        } else if coreViewer.canGoBack {
            coreViewer.goBack()
        }
    }
    
    func reinvigorateContent() {
        coreViewer.reload()
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom))
                .padding()
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 5) // Neumorphic shadow
                .shadow(color: .white.opacity(0.7), radius: 10, x: -5, y: -5)
        )
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: UUID())
    }
}
