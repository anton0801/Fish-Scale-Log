import SwiftUI
import WebKit
import Combine

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

struct ScaleWebEnclosure: UIViewRepresentable {
    let resourceAddr: URL
    
    @StateObject private var webOverseer = ScaleWebOverseer()
    
    func makeCoordinator() -> ScaleRouteManager {
        ScaleRouteManager(overseer: webOverseer)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webOverseer.initCoreViewer()
        webOverseer.coreViewer.uiDelegate = context.coordinator
        webOverseer.coreViewer.navigationDelegate = context.coordinator
        
        webOverseer.sessionHandler.loadAndSetSessions()
        webOverseer.coreViewer.load(URLRequest(url: resourceAddr))
        
        return webOverseer.coreViewer
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}


