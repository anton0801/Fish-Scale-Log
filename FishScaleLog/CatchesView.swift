import SwiftUI
import WebKit
import Combine

struct PushMainAppAcceptationView: View {
    
    @EnvironmentObject var viewModel: LogSupervisorViewModel
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("main_push_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                
                VStack(spacing: 18) {
                    Spacer()
                    
                    texts
                    
                    Button {
                        viewModel.manageConsentApproval()
                    } label: {
                        Image("push_accepting_button")
                            .resizable()
                            .frame(width: 350, height: 55)
                    }
                    
                    Button {
                        viewModel.manageConsentSkip()
                    } label: {
                        Text("SKIP")
                            .foregroundColor(.white)
                            .font(.custom("BagelFatOne-Regular", size: 18))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 24)
                }
                
            }
        }
        .ignoresSafeArea()
    }
    
    private var texts: some View {
        VStack(spacing: 18) {
            Text("ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS")
                .foregroundColor(.white)
                .font(.custom("BagelFatOne-Regular", size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 42)
            
            Text("STAY TUNED WITH BEST OFFERS FROM OUR CASINO")
                .foregroundColor(.white)
                .font(.custom("BagelFatOne-Regular", size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 42)
        }
    }
    
}


struct CatchesView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @State private var showDetails: FishCatch? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.catches) { catchItem in
                    CatchCard(catchItem: catchItem)
                        .onTapGesture {
                            showDetails = catchItem
                        }
                }
                .onDelete { indexSet in
                    let itemsToDelete = indexSet.map { viewModel.catches[$0] }
                    itemsToDelete.forEach { viewModel.deleteCatch($0) }
                }
            }
            .navigationTitle("Catches")
            .sheet(item: $showDetails) { catchItem in
                CatchDetailsView(viewModel: viewModel, catchItem: catchItem)
            }
            .background(LinearGradient(gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
        }
    }
}

struct CatchCard: View {
    let catchItem: FishCatch
    
    var body: some View {
        HStack {
            if let photoData = catchItem.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            } else {
                Image(systemName: "fish.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                    .padding()
            }
            
            VStack(alignment: .leading) {
                Text(catchItem.fishType)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(catchItem.weight, specifier: "%.2f") \(catchItem.unit) - \(catchItem.date, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.green.opacity(0.7))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 4, y: 4)
                .shadow(color: .white.opacity(0.6), radius: 8, x: -4, y: -4)
        )
    }
}



// Builder for WKWebViewConfiguration
class WebConfigBuilder {
    private var config = WKWebViewConfiguration()
    
    func enableInlinePlayback() -> Self {
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        return self
    }
    
    func setPreferences(javaScriptEnabled: Bool = true, autoOpenWindows: Bool = true) -> Self {
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = javaScriptEnabled
        prefs.javaScriptCanOpenWindowsAutomatically = autoOpenWindows
        config.preferences = prefs
        return self
    }
    
    func setPagePreferences(allowJS: Bool = true) -> Self {
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = allowJS
        config.defaultWebpagePreferences = pagePrefs
        return self
    }
    
    func build() -> WKWebViewConfiguration {
        return config
    }
}
