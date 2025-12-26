import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @State private var showExport = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Preferences")) {
                    Picker("Units", selection: $viewModel.preferredUnit) {
                        Text("kg").tag("kg")
                        Text("lb").tag("lb")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Data")) {
                    Button("Reset Data", role: .destructive) {
                        viewModel.resetData()
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Fish Scale Log v1.0")
                    Text("Privacy Policy: Your data stays on your device.")
                }
            }
            .navigationTitle("Settings")

        }
    }
}
