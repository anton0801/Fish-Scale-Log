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
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddCatchView(viewModel: viewModel, existingCatch: catchItem)
            }
        }
    }
}
