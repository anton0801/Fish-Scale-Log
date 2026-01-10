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
