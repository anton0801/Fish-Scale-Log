import SwiftUI

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
        }
    }
}

struct CatchCard: View {
    let catchItem: FishCatch
    
    var body: some View {
        HStack {
            Image(systemName: "fish")
                .font(.title)
                .foregroundColor(.yellow)
                .padding()
            
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
        .background(Color.green.opacity(0.6).cornerRadius(10))
        .shadow(radius: 3)
    }
}
