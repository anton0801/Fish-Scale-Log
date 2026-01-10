import SwiftUI
import WebKit
import Combine

struct ContentView: View {
    @AppStorage("onboardingSeen") private var onboardingSeen: Bool = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if !onboardingSeen {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PushMainAppAcceptationView()
}

struct Bubble: View {
    @State private var yOffset: CGFloat = 0
    @State private var xSway: CGFloat = 0
    let size: CGFloat
    let duration: Double
    let delay: Double
    let swayAmount: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: size, height: size)
            .offset(x: xSway, y: yOffset)
            .blur(radius: 2)
            .onAppear {
                withAnimation(Animation.linear(duration: duration).delay(delay).repeatForever(autoreverses: false)) {
                    yOffset = -UIScreen.main.bounds.height - size
                }
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(delay)) {
                    xSway = swayAmount
                }
            }
    }
}

struct SplashScreenView: View {
    
    @StateObject private var viewModel = LogSupervisorViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.ongoingLogPhase == .bootstrapping || viewModel.revealConsentDialog {
                SplashView()
                    .preferredColorScheme(.dark)
            }

            if viewModel.revealConsentDialog {
                PushMainAppAcceptationView()
                    .environmentObject(viewModel)
            } else {
                switch viewModel.ongoingLogPhase {
                case .bootstrapping:
                    EmptyView()
                    
                case .operational:
                    if viewModel.logDestination != nil {
                        PrimaryResourceView()
                    } else {
                        ContentView()
                    }
                    
                case .deprecated:
                    ContentView()
                    
                case .unreachable:
                    NoConnectionView()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ConversionDataReceived"))) { notice in
            if let metrics = notice.userInfo?["conversionData"] as? [String: Any] {
                viewModel.manageAcquisitionMetrics(metrics)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("deeplink_values"))) { notice in
            if let metrics = notice.userInfo?["deeplinksData"] as? [String: Any] {
                viewModel.manageEntryPointMetrics(metrics)
            }
        }
    }
    
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var waveOffset: CGFloat = 0.0
    @State private var particleOpacity: Double = 0.5
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            ZStack {
                // Background gradient simulating deep water
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.green.opacity(0.7), Color.blue.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                Image(isLandscape ? "second_bg" : "main_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                // Subtle wave animation at the bottom
                WaveShape(offset: waveOffset)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
                    .offset(y: UIScreen.main.bounds.height / 2 - 50)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                            waveOffset = -UIScreen.main.bounds.width
                        }
                    }
                
                // Enhanced bubbles rising with sway
                ForEach(0..<25) { index in
                    Bubble(
                        size: CGFloat.random(in: 8...45),
                        duration: Double.random(in: 3...7),
                        delay: Double(index) * 0.15,
                        swayAmount: CGFloat.random(in: -25...25)
                    )
                    .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: UIScreen.main.bounds.height + CGFloat.random(in: 0...150))
                    .opacity(0.2)
                }
                
                ForEach(0..<15) { index in
                    Circle()
                        .fill(Color.yellow.opacity(particleOpacity))
                        .frame(width: 3, height: 3)
                        .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                        .animation(Animation.easeInOut(duration: Double.random(in: 2...5)).repeatForever(autoreverses: true), value: particleOpacity)
                        .onAppear {
                            particleOpacity = 0.2
                        }
                }
                
                Circle()
                    .stroke(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale * 1.4)
                    .opacity(1 - opacity * 0.5)
                    .blur(radius: 4)
                
                VStack {
                    Spacer()
                    Text("Loading...")
                        .font(.custom("BagelFatOne-Regular", size: 42))
                        .foregroundColor(.white)
                        .padding(.bottom, !isLandscape ? 72 : 8)
                }
                
                VStack {
                    HStack {
                        Image(systemName: "fish")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.yellow)
                            .rotationEffect(.degrees(rotation))
                            .scaleEffect(scale)
                            .shadow(color: .yellow.opacity(glowOpacity), radius: 10)
                    }
                    .padding()
                }
                .onAppear {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.45).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                    withAnimation(.easeInOut(duration: 1.8)) {
                        opacity = 1.0
                    }
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.9
                    }
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: true)) {
                        rotation = 6.0
                    }
                }
            
                Image("fish_scale_log_app")
                    .resizable()
                    .frame(width: 300, height: 300)
            }
        }
        .ignoresSafeArea()
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
        
        for x in stride(from: 0, to: rect.width + 100, by: 10) {
            let y = sin((x + offset) / 50) * 20 + rect.height * 0.5
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("onboardingSeen") private var onboardingSeen: Bool = false
    
    let pages = [
        OnboardingPage(title: "Log fish weight easily", subtitle: "Capture every catch with precision and ease.", image: "fish", color: .blue),
        OnboardingPage(title: "Track your biggest catches", subtitle: "Relive your triumphs and set new records.", image: "scale.mass", color: .green),
        OnboardingPage(title: "See your fishing progress", subtitle: "Visualize your journey and improve over time.", image: "chart.line.uptrend.xyaxis", color: .teal)
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [pages[currentPage].color.opacity(0.95), Color.gray.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)
            
            ForEach(0..<20) { index in
                Bubble(
                    size: CGFloat.random(in: 6...40),
                    duration: Double.random(in: 4...8),
                    delay: Double(index) * 0.25,
                    swayAmount: CGFloat.random(in: -20...20)
                )
                .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: UIScreen.main.bounds.height + CGFloat.random(in: 0...120))
            }
            
            ForEach(0..<12) { index in
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 4, height: 4)
                    .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                    .animation(Animation.easeInOut(duration: Double.random(in: 2.5...5.5)).repeatForever(autoreverses: true), value: UUID())
            }
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pages[index]
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(maxHeight: .infinity)
                .transition(.scale)
                
                HStack {
                    if currentPage > 0 {
                        Button("Skip") {
                            withAnimation(.spring()) {
                                onboardingSeen = true
                            }
                        }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.6).cornerRadius(12))
                        .shadow(color: .black.opacity(0.4), radius: 6)
                        .scaleEffect(1.0)
                        .animation(.easeInOut, value: currentPage)
                    }
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        }
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing).cornerRadius(12))
                        .shadow(color: .yellow.opacity(0.6), radius: 6)
                    } else {
                        Button("Start") {
                            withAnimation(.spring()) {
                                onboardingSeen = true
                            }
                        }
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing).cornerRadius(12))
                        .shadow(color: .yellow.opacity(0.6), radius: 6)
                    }
                }
                .padding()
            }
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
    
    @State private var offset: CGFloat = 0.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var glow: Double = 0.0
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom))
                .offset(y: offset * 0.25)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .yellow.opacity(glow), radius: 20)
                .padding()
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        scale = 1.2
                        rotation = 4.0
                        glow = 0.8
                    }
                }
            
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: color.opacity(0.6), radius: 6)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 10)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.height
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
        )
    }
}

// Main Tab View
struct MainTabView: View {
    @State private var showAddCatch = false
    @StateObject private var viewModel = CatchesViewModel()
    @StateObject private var locationManager = LocationManager() // New for GPS
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            CatchesView(viewModel: viewModel)
                .tabItem {
                    Label("Catches", systemImage: "list.bullet")
                }
            
            MapView(viewModel: viewModel, locationManager: locationManager) // New tab
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
            
            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.yellow)
        .overlay(
            Button(action: {
                showAddCatch = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 5)
            }
            .padding(.bottom, 50)
            .sheet(isPresented: $showAddCatch) {
                AddCatchView(viewModel: viewModel, locationManager: locationManager)
            },
            alignment: .bottomTrailing
        )
        .background(Color.gray.opacity(0.1))
        .preferredColorScheme(.dark)
        .onAppear {
            locationManager.requestLocation()
        }
    }
}
