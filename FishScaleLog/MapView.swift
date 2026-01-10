import SwiftUI
import MapKit
import CoreLocation
import WebKit

struct MapView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @ObservedObject var locationManager: LocationManager
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: viewModel.catches.filter { $0.coordinate != nil }) { catchItem in
                MapAnnotation(coordinate: catchItem.coordinate!) {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "fish.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        )
                        .onTapGesture {
                            // Show details popover or something
                        }
                }
            }
            .ignoresSafeArea()
            .navigationTitle("Catch Map")
            .onAppear {
                if let userLocation = locationManager.location {
                    region.center = userLocation
                }
            }
        }
    }
}


struct NoConnectionView: View {
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                Image(isLandscape ? "connection_issue_second_bg" : "connection_issue_main_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .opacity(0.7)
                
                Image("connection_issue")
                    .resizable()
                    .frame(width: 300, height: 300)
            }
            
        }
        .ignoresSafeArea()
    }
}


// Builder for WKWebView Settings
class WebViewSettingsBuilder {
    private let webView: WKWebView
    
    init(webView: WKWebView) {
        self.webView = webView
    }
    
    func disableZoom() -> Self {
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        return self
    }
    
    func disableBounces() -> Self {
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        return self
    }
    
    func enableNavigationGestures() -> Self {
        webView.allowsBackForwardNavigationGestures = true
        return self
    }
    
    func apply() {
        // No return, just applies
    }
}
