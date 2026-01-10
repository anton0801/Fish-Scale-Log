import SwiftUI
import MapKit
import AppsFlyerLib
import Firebase
import FirebaseMessaging
import WebKit
import CoreLocation

struct WebResource {
    let address: URL
}

// Interactor
protocol ResourceInteractorProtocol {
    func retrieveStartupAddress() -> String?
    func retrieveStoredAddress() -> String?
    func eraseStartupAddress()
}

struct FishCatch: Identifiable, Codable {
    let id: UUID
    var fishType: String
    var weight: Double
    var unit: String
    var length: Double?
    var date: Date
    var location: String?
    var coordinate: CLLocationCoordinate2D?
    var notes: String?
    var photoData: Data?
    
    init(id: UUID = UUID(), fishType: String, weight: Double, unit: String, length: Double? = nil, date: Date = Date(), location: String? = nil, coordinate: CLLocationCoordinate2D? = nil, notes: String? = nil, photoData: Data? = nil) {
        self.id = id
        self.fishType = fishType
        self.weight = weight
        self.unit = unit
        self.length = length
        self.date = date
        self.location = location
        self.coordinate = coordinate
        self.notes = notes
        self.photoData = photoData
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case fishType
        case weight
        case unit
        case length
        case date
        case location
        case notes
        case photoData
        case latitude
        case longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        fishType = try container.decode(String.self, forKey: .fishType)
        weight = try container.decode(Double.self, forKey: .weight)
        unit = try container.decode(String.self, forKey: .unit)
        length = try container.decodeIfPresent(Double.self, forKey: .length)
        date = try container.decode(Date.self, forKey: .date)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        
        if let lat = try? container.decode(Double.self, forKey: .latitude),
           let lon = try? container.decode(Double.self, forKey: .longitude) {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fishType, forKey: .fishType)
        try container.encode(weight, forKey: .weight)
        try container.encode(unit, forKey: .unit)
        try container.encodeIfPresent(length, forKey: .length)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(photoData, forKey: .photoData)
        
        if let coord = coordinate {
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        }
    }
}


class ResourceInteractor: ResourceInteractorProtocol {
    func retrieveStartupAddress() -> String? {
        UserDefaults.standard.string(forKey: "temp_url")
    }
    
    func retrieveStoredAddress() -> String? {
        UserDefaults.standard.string(forKey: "persisted_destination")
    }
    
    func eraseStartupAddress() {
        UserDefaults.standard.removeObject(forKey: "temp_url")
    }
}

// Presenter
protocol ResourcePresenterProtocol: ObservableObject {
    var activeResource: URL? { get set }
    func initializeResource()
    func updateResource()
}


protocol AppStateRepository {
    var isInitialExecution: Bool { get }
    func retrieveStoredDestination() -> URL?
    func persistDestination(_ url: String)
    func assignAppCondition(_ condition: String)
    func logExecutionCompleted()
    func retrieveAppCondition() -> String?
}

class AppStateRepositoryImpl: AppStateRepository {
    private let storage = UserDefaults.standard
    
    var isInitialExecution: Bool {
        !storage.bool(forKey: "executedPreviously")
    }
    
    func retrieveStoredDestination() -> URL? {
        if let str = storage.string(forKey: "persisted_destination"), let url = URL(string: str) {
            return url
        }
        return nil
    }
    
    func persistDestination(_ url: String) {
        storage.set(url, forKey: "persisted_destination")
    }
    
    func assignAppCondition(_ condition: String) {
        storage.set(condition, forKey: "app_condition")
    }
    
    func logExecutionCompleted() {
        storage.set(true, forKey: "executedPreviously")
    }
    
    func retrieveAppCondition() -> String? {
        storage.string(forKey: "app_condition")
    }
}


struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlocked: Bool
}

// Predefined fish types
let fishTypes = ["Pike", "Carp", "Perch", "Trout", "Bass", "Salmon", "Catfish", "Other"]


