import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: CatchesViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    StatsCard(title: "Total Weight Caught", value: "\(viewModel.totalWeight.format()) \(viewModel.preferredUnit)", icon: "scalemass")
                    StatsCard(title: "Average Weight", value: "\(viewModel.averageWeight.format()) \(viewModel.preferredUnit)", icon: "chart.bar")
                    StatsCard(title: "Biggest Catch", value: viewModel.biggestFish?.weight.description ?? "None", icon: "trophy")
                    StatsCard(title: "Most Caught Fish", value: viewModel.mostCaughtFish, icon: "fish")
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .green.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
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
                .foregroundColor(.yellow)
                .padding()
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.8).cornerRadius(15))
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
    }
}

