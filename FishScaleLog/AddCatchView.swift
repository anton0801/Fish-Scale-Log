import SwiftUI
import WebKit
import PhotosUI

struct AddCatchView: View {
    @ObservedObject var viewModel: CatchesViewModel
    @ObservedObject var locationManager: LocationManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fishType = fishTypes[0]
    @State private var weight: String = ""
    @State private var unit = "kg"
    @State private var length: String = ""
    @State private var date = Date()
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var photoItem: PhotosPickerItem? // New for photo
    @State private var photoData: Data? // New
    
    @State private var isEditing = false
    @State private var existingCatch: FishCatch?
    
    init(viewModel: CatchesViewModel, locationManager: LocationManager, existingCatch: FishCatch? = nil) {
        self.viewModel = viewModel
        self.locationManager = locationManager
        self._existingCatch = State(initialValue: existingCatch)
        if let catchItem = existingCatch {
            _fishType = State(initialValue: catchItem.fishType)
            _weight = State(initialValue: "\(catchItem.weight)")
            _unit = State(initialValue: catchItem.unit)
            _length = State(initialValue: catchItem.length != nil ? "\(catchItem.length!)" : "")
            _date = State(initialValue: catchItem.date)
            _location = State(initialValue: catchItem.location ?? "")
            _notes = State(initialValue: catchItem.notes ?? "")
            _photoData = State(initialValue: catchItem.photoData)
            _isEditing = State(initialValue: true)
        } else {
            _unit = State(initialValue: viewModel.preferredUnit)
            locationManager.requestLocation() // Auto-fetch location
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Catch Details").font(.headline)) {
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
                    
                    if let coord = locationManager.location {
                        Text("Current GPS: \(coord.latitude), \(coord.longitude)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    TextField("Notes (optional)", text: $notes)
                    
                    // New: Photo Picker
                    PhotosPicker("Add Photo (optional)", selection: $photoItem, matching: .images)
                        .onChange(of: photoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    photoData = data
                                }
                            }
                        }
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                    }
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
                            coordinate: locationManager.location,
                            notes: notes.isEmpty ? nil : notes,
                            photoData: photoData
                        )
                        
                        if isEditing {
                            viewModel.updateCatch(newCatch)
                        } else {
                            viewModel.addCatch(newCatch)
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(weight.isEmpty)
                }
            }
            .background(Color.blue.opacity(0.1))
        }
    }
}


class SessionHandler {
    func loadAndSetSessions() {
        guard let archivedSessions = UserDefaults.standard.object(forKey: "archived_tokens") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        
        let sessionStore = ScaleWebOverseer().coreViewer?.configuration.websiteDataStore.httpCookieStore
        
        let decodedSessions = archivedSessions.values.flatMap { $0.values }.compactMap { attrs in
            HTTPCookie(properties: attrs as [HTTPCookiePropertyKey: Any])
        }
        
        decodedSessions.forEach { session in
            sessionStore?.setCookie(session)
        }
    }
    
    func gatherAndArchiveSessions(from viewer: WKWebView) {
        viewer.configuration.websiteDataStore.httpCookieStore.getAllCookies { sessions in
            var realmDict: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for session in sessions {
                var innerDict = realmDict[session.domain] ?? [:]
                if let props = session.properties {
                    innerDict[session.name] = props
                }
                realmDict[session.domain] = innerDict
            }
            
            UserDefaults.standard.set(realmDict, forKey: "archived_tokens")
        }
    }
}

