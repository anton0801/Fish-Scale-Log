import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CatchesViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    OverviewCard(title: "Total Catches", value: "\(viewModel.totalCatches)", icon: "list.bullet")
                    if let biggest = viewModel.biggestFish {
                        OverviewCard(title: "Biggest Fish", value: "\(biggest.fishType) - \(biggest.weight) \(biggest.unit)", icon: "trophy")
                    } else {
                        OverviewCard(title: "Biggest Fish", value: "None yet", icon: "trophy")
                    }
                    if let last = viewModel.lastCatch {
                        OverviewCard(title: "Last Catch", value: "\(last.fishType) - \(last.weight) \(last.unit)", icon: "clock")
                    } else {
                        OverviewCard(title: "Last Catch", value: "None yet", icon: "clock")
                    }
                }
                .padding()
            }
            .navigationTitle("Overview")
            .background(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .green.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
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
