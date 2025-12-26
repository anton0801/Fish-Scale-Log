import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingSeen") private var onboardingSeen: Bool = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else if !onboardingSeen {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
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
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(delay)) {
                    xSway = swayAmount
                }
            }
    }
}

// Splash View - Enhanced with improved bubbles, wave animation, glow effects
struct SplashView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var waveOffset: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient simulating deep water
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.green.opacity(0.7), Color.blue.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
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
            ForEach(0..<20) { index in
                Bubble(
                    size: CGFloat.random(in: 10...40),
                    duration: Double.random(in: 4...8),
                    delay: Double(index) * 0.2,
                    swayAmount: CGFloat.random(in: -20...20)
                )
                .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: UIScreen.main.bounds.height + CGFloat.random(in: 0...100))
            }
            
            // Ripples effect around icons
            Circle()
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 200)
                .scaleEffect(scale * 1.5)
                .opacity(1 - opacity)
                .blur(radius: 5)
            
            VStack {
                // Icons with rotation, scale, and glow
                HStack {
                    Image(systemName: "fish")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                        .shadow(color: .yellow.opacity(glowOpacity), radius: 10)
                    
                    Image(systemName: "scale.mass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(-rotation))
                        .scaleEffect(scale)
                        .shadow(color: .yellow.opacity(glowOpacity), radius: 10)
                }
                .padding()
                
                // Title with fade-in, slight wave distortion simulation
                if #available(iOS 17.0, *) {
                    Text("Fish Scale Log")
                        .font(.system(size: 50, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .yellow.opacity(glowOpacity), radius: 15)
                        .opacity(opacity)
                        .distortionEffect(
                            ShaderLibrary.wave(
                                .float(0.5), // amplitude
                                .float(2.0), // frequency
                                .float(waveOffset / 100) // phase
                            ),
                            maxSampleOffset: CGSize(width: 10, height: 10)
                        )
                } else {
                    Text("Fish Scale Log")
                        .font(.system(size: 50, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .yellow.opacity(glowOpacity), radius: 15)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
                    scale = 1.0
                }
                withAnimation(.easeInOut(duration: 1.5)) {
                    opacity = 1.0
                }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.8
                }
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                    rotation = 8.0
                }
            }
        }
    }
}

// Wave Shape for water effect
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

// Onboarding View - Enhanced with bubbles, parallax, dynamic backgrounds, particle effects
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
            // Dynamic background gradient that transitions smoothly
            LinearGradient(gradient: Gradient(colors: [pages[currentPage].color.opacity(0.9), Color.gray.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // Bubbles rising across all pages
            ForEach(0..<15) { index in
                Bubble(
                    size: CGFloat.random(in: 8...35),
                    duration: Double.random(in: 5...9),
                    delay: Double(index) * 0.3,
                    swayAmount: CGFloat.random(in: -15...15)
                )
                .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: UIScreen.main.bounds.height + CGFloat.random(in: 0...100))
            }
            
            // Subtle underwater particles (small dots floating)
            ForEach(0..<10) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 5, height: 5)
                    .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                    .animation(Animation.easeInOut(duration: Double.random(in: 3...6)).repeatForever(autoreverses: true), value: UUID())
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
                
                HStack {
                    if currentPage > 0 {
                        Button("Skip") {
                            onboardingSeen = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.5).cornerRadius(10))
                        .shadow(color: .black.opacity(0.3), radius: 5)
                    }
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut) {
                                currentPage += 1
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.yellow.cornerRadius(10))
                        .shadow(color: .yellow.opacity(0.5), radius: 5)
                    } else {
                        Button("Start") {
                            onboardingSeen = true
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.yellow.cornerRadius(10))
                        .shadow(color: .yellow.opacity(0.5), radius: 5)
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
            // Enhanced image with parallax, scale pulse, rotation, glow
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .foregroundColor(.yellow)
                .offset(y: offset * 0.3)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .shadow(color: .yellow.opacity(glow), radius: 15)
                .padding()
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.15
                        rotation = 5.0
                        glow = 0.7
                    }
                }
            
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: color.opacity(0.5), radius: 5)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.height
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
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
                AddCatchView(viewModel: viewModel)
            },
            alignment: .bottomTrailing
        )
        .background(Color.gray.opacity(0.1))
    }
}
