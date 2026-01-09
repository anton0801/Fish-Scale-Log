import SwiftUI

struct CatchDetailsView: View {
    @ObservedObject var viewModel: CatchesViewModel
    let catchItem: FishCatch
    @State private var showEdit = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let photoData = catchItem.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    
                    HStack {
                        Text("Fish Type")
                        Spacer()
                        Text(catchItem.fishType)
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(catchItem.weight, specifier: "%.2f") \(catchItem.unit)")
                    }
                    if let length = catchItem.length {
                        HStack {
                            Text("Length")
                            Spacer()
                            Text("\(length, specifier: "%.2f") cm")
                        }
                    }
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(catchItem.date, style: .date)
                    }
                    if let location = catchItem.location {
                        HStack {
                            Text("Location")
                            Spacer()
                            Text(location)
                        }
                    }
                    if let notes = catchItem.notes {
                        HStack {
                            Text("Notes")
                            Spacer()
                            Text(notes)
                        }
                    }
                }
            }
            .navigationTitle("Catch Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit") {
                            showEdit = true
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.deleteCatch(catchItem)
                            presentationMode.wrappedValue.dismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddCatchView(viewModel: viewModel, locationManager: LocationManager(), existingCatch: catchItem)
            }
            .background(Color.teal.opacity(0.1))
        }
    }
}
