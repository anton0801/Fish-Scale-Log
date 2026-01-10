import Foundation
import SwiftUI


class CatchesViewModel: ObservableObject {
    @AppStorage("catches") private var catchesData: Data = Data()
    @AppStorage("preferredUnit") var preferredUnit: String = "kg"
    
    @Published var catches: [FishCatch] = []
    
    init() {
        loadCatches()
    }
    
    func loadCatches() {
        if let decoded = try? JSONDecoder().decode([FishCatch].self, from: catchesData) {
            catches = decoded.sorted(by: { $0.date > $1.date })
        }
    }
    
    func saveCatches() {
        if let encoded = try? JSONEncoder().encode(catches) {
            catchesData = encoded
        }
    }
    
    func addCatch(_ newCatch: FishCatch) {
        catches.append(newCatch)
        saveCatches()
    }
    
    func updateCatch(_ updatedCatch: FishCatch) {
        if let index = catches.firstIndex(where: { $0.id == updatedCatch.id }) {
            catches[index] = updatedCatch
            saveCatches()
        }
    }
    
    func deleteCatch(_ catchToDelete: FishCatch) {
        catches.removeAll { $0.id == catchToDelete.id }
        saveCatches()
    }
    
    func resetData() {
        catches = []
        saveCatches()
    }
    
    // Stats calculations
    var totalCatches: Int { catches.count }
    
    var biggestFish: FishCatch? {
        catches.max(by: { $0.weight < $1.weight })
    }
    
    var lastCatch: FishCatch? {
        catches.first
    }
    
    var totalWeight: Double {
        catches.reduce(0) { $0 + $1.weight }
    }
    
    var averageWeight: Double {
        totalCatches > 0 ? totalWeight / Double(totalCatches) : 0
    }
    
    var mostCaughtFish: String {
        let counts = Dictionary(grouping: catches, by: { $0.fishType }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }
    
    var achievements: [Achievement] {
        let ach = [
            Achievement(id: "firstCatch", title: "First Catch", description: "Log your first fish!", icon: "fish.fill", unlocked: totalCatches >= 1),
            Achievement(id: "tenCatches", title: "Deca-Angler", description: "Log 10 catches", icon: "10.circle", unlocked: totalCatches >= 10),
            Achievement(id: "bigOne", title: "The Big One", description: "Catch a fish over 5kg/lb", icon: "trophy.fill", unlocked: biggestFish?.weight ?? 0 >= 5),
            Achievement(id: "diverse", title: "Diverse Angler", description: "Catch 5 different types", icon: "leaf.fill", unlocked: Set(catches.map { $0.fishType }).count >= 5)
        ]
        return ach
    }
}
