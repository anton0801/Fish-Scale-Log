import SwiftUI

struct FishCatch: Identifiable, Codable {
    let id: UUID
    var fishType: String
    var weight: Double
    var unit: String // "kg" or "lb"
    var length: Double?
    var date: Date
    var location: String?
    var notes: String?
    
    init(id: UUID = UUID(), fishType: String, weight: Double, unit: String, length: Double? = nil, date: Date = Date(), location: String? = nil, notes: String? = nil) {
        self.id = id
        self.fishType = fishType
        self.weight = weight
        self.unit = unit
        self.length = length
        self.date = date
        self.location = location
        self.notes = notes
    }
}

// Predefined fish types
let fishTypes = ["Pike", "Carp", "Perch", "Trout", "Bass", "Salmon", "Catfish", "Other"]
