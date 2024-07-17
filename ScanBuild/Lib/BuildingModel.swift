import Foundation

class BuildingModel: ObservableObject {
    private static var _instance: BuildingModel = BuildingModel()
    @Published var buildings: [Building]
    
    private init() {
        self.buildings = []
    }
    
    static func getInstance() -> BuildingModel {
        return _instance
    }
    
    func getBuildings() -> [Building] {
        return buildings
    }
    
    func addBuilding(building: Building) {
        buildings.append(building)
    }
    
    func deleteBuilding(id: UUID) {
        buildings.removeAll { $0.id == id }
    }
}
