import SwiftUI

extension Double {
    func format(_ digits: Int = 2) -> String {
        String(format: "%.\(digits)f", self)
    }
}

struct StatsView: View {
    @ObservedObject var viewModel: CatchesViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    StatsCard(title: "Total Weight Caught", value: "\(String(format: "%.2f", viewModel.totalWeight)) \(viewModel.preferredUnit)", icon: "scale.mass.fill")
                    StatsCard(title: "Average Weight", value: "\(String(format: "%.2f", viewModel.averageWeight)) \(viewModel.preferredUnit)", icon: "chart.bar.fill")
                    StatsCard(title: "Biggest Catch", value: viewModel.biggestFish?.weight.description ?? "None", icon: "trophy.fill")
                    StatsCard(title: "Most Caught Fish", value: viewModel.mostCaughtFish, icon: "fish.fill")
                    
                    // New: Achievements
                    Section(header: Text("Achievements").font(.title2.bold()).foregroundColor(.white).padding(.top, 20)) {
                        ForEach(viewModel.achievements) { ach in
                            AchievementCard(achievement: ach)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(LinearGradient(gradient: Gradient(colors: [.teal.opacity(0.4), .blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
    }
}

struct StatsCard: View {
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
                .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 5)
                .shadow(color: .white.opacity(0.7), radius: 10, x: -5, y: -5)
        )
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    @State private var glow: Double = 0.0
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundStyle(achievement.unlocked ? LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color.gray]), startPoint: .top, endPoint: .bottom))
                .padding()
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .shadow(color: .yellow.opacity(glow), radius: 10)
            
            VStack(alignment: .leading) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(achievement.unlocked ? LinearGradient(gradient: Gradient(colors: [.green.opacity(0.8), .teal.opacity(0.7)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 5, y: 5)
                .shadow(color: .white.opacity(0.7), radius: 10, x: -5, y: -5)
        )
        .scaleEffect(achievement.unlocked ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: achievement.unlocked)
        .onAppear {
            if achievement.unlocked {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    scale = 1.1
                    rotation = 5.0
                    glow = 0.8
                }
            }
        }
    }
}
