import SwiftUI

struct AddCatchView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fishType = fishTypes[0]
    @State private var weight: String = ""
    @State private var unit = "kg"
    @State private var length: String = ""
    @State private var date = Date()
    @State private var location: String = ""
    @State private var notes: String = ""
    
    @State private var isEditing = false
    @State private var existingCatch: FishCatch?
    
    init(viewModel: CatchesViewModel, existingCatch: FishCatch? = nil) {
        self.viewModel = viewModel
        self._existingCatch = State(initialValue: existingCatch)
        if let catchItem = existingCatch {
            _fishType = State(initialValue: catchItem.fishType)
            _weight = State(initialValue: "\(catchItem.weight)")
            _unit = State(initialValue: catchItem.unit)
            _length = State(initialValue: catchItem.length != nil ? "\(catchItem.length!)" : "")
            _date = State(initialValue: catchItem.date)
            _location = State(initialValue: catchItem.location ?? "")
            _notes = State(initialValue: catchItem.notes ?? "")
            _isEditing = State(initialValue: true)
        } else {
            _unit = State(initialValue: viewModel.preferredUnit)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Catch Details")) {
                    Picker("Fish Type", selection: $fishType) {
                        ForEach(fishTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    
                    HStack {
                        Text("Weight")
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            Text("kg").tag("kg")
                            Text("lb").tag("lb")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Length (optional)")
                        TextField("Length", text: $length)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Location (optional)", text: $location)
                    
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle(isEditing ? "Edit Catch" : "Add Catch")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard let weightDouble = Double(weight) else { return }
                        let lengthDouble = Double(length)
                        
                        let newCatch = FishCatch(
                            id: existingCatch?.id ?? UUID(),
                            fishType: fishType,
                            weight: weightDouble,
                            unit: unit,
                            length: lengthDouble,
                            date: date,
                            location: location.isEmpty ? nil : location,
                            notes: notes.isEmpty ? nil : notes
                        )
                        
                        if isEditing {
                            viewModel.updateCatch(newCatch)
                        } else {
                            viewModel.addCatch(newCatch)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
}
