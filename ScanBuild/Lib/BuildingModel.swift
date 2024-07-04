import Foundation

class BuildingModel: ObservableObject {
    private static var INSTANCE: BuildingModel?
    
    private static var SCAN_BUILD_ROOT: String {
        get {
            guard let serverURL = ProcessInfo.processInfo.environment["SCAN_BUILD_ROOT"] else {
                fatalError("unspecified base ScanBuild Root")
            }
            return serverURL
        }
    }
    
    public static func getInstance() -> BuildingModel {
        if self.INSTANCE == nil {
            self.INSTANCE = BuildingModel()
        }
        return self.INSTANCE!
    }
    
    private static let LOGGER = Logger(tag: String(describing: BuildingModel.self))
    private let fileManager = FileManager.default
    
    @Published var buildings: [Building] = []
    
    func getBuildings() -> [Building] {
        return Array(buildings)
    }
    
    private init() {
        let homeDirectory = URL(filePath: NSHomeDirectory())
        let scanBuildDirectory = homeDirectory.appendingPathComponent(BuildingModel.SCAN_BUILD_ROOT)
        
        // Crea la directory "ScanBuild" nella home se non esiste.
        if !self.fileManager.fileExists(atPath: scanBuildDirectory.path) {
            do {
                try self.fileManager.createDirectory(at: scanBuildDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                BuildingModel.LOGGER.log("An error occurred while creating the \(BuildingModel.SCAN_BUILD_ROOT) directory. Reason: \(error)")
            }
        } else {
            // Si caricano le directory dei vari musei.
            Task {
                // TODO: Leggere le cartelle relative ai musei.
            }
        }
        
//        // Aggiungi 10 edifici hardcoded
//        for i in 1...10 {
//            let building = Building(name: "Building \(i)", floors: [], date: "Date \(i)", fileURL: URL(fileURLWithPath: ""))
//            self.buildings.append(building)
//        }
//        
//        // Aggiungi 5 piani al primo edificio
//        for j in 1...5 {
//            let floor = Floor(name: "Floor \(j)", fileURL: URL(fileURLWithPath: ""), idBuilding: buildings[0].id, rooms: [], date: "Date \(j)")
//            self.buildings[0].floors.append(floor)
//            for k in 1...5{
//                let room = Room(roomName: "Room \(k)", floorName: floor.name, idFloor: floor.id, fileURL: URL(fileURLWithPath: ""), associationMatrix: [[]], referenceMarkers: [], transitionZones: [])
//                self.buildings[0].floors[j-1].rooms.append(room)
//                self.buildings[0].connections.addRoomToConnection(room: room)
//            }
//            
//        }
//        
//        
//        for q in 0..<3 {
//            self.buildings[0].connections.createConnection(room1: self.buildings[0].floors[q].rooms[0], room2: self.buildings[0].floors[q+1].rooms[0])
//        }
    }
    
    
    @MainActor func addBuilding(building: Building) {
        buildings.append(building)
        saveBuildings(buildings)
    }
    
    @MainActor func deleteBuilding(at index: Int) {
        buildings.remove(at: index)
        saveBuildings(buildings)
    }
    
    @MainActor func renameBuilding(at index: Int, newName: String) {
        buildings[index].name = newName
        saveBuildings(buildings)
    }
    
    @MainActor func addFloorToBuilding(at buildingIndex: Int, floor: Floor) {
        buildings[buildingIndex].floors.append(floor)
        saveBuildings(buildings)
    }
    
    @MainActor func deleteFloorFromBuilding(at buildingIndex: Int, floorIndex: Int) {
        buildings[buildingIndex].floors.remove(at: floorIndex)
        saveBuildings(buildings)
    }
    
    @MainActor func renameFloorInBuilding(at buildingIndex: Int, floorIndex: Int, newName: String) {
        buildings[buildingIndex].floors[floorIndex].name = newName
        saveBuildings(buildings)
    }
    
    @MainActor func saveFloorOfBuilding(at buildingIndex: Int, floorIndex: Int, floor: Floor) {
        buildings[buildingIndex].floors[floorIndex] = floor
        saveBuildings(buildings)
    }
    
    @MainActor func addRoomToFloor(at buildingIndex: Int, floorIndex: Int, room: Room) {
        buildings[buildingIndex].floors[floorIndex].rooms.append(room)
        buildings[buildingIndex].connections.addRoomToConnection(room: room)
        saveBuildings(buildings)
    }
    
    @MainActor func deleteRoomFromFloor(at buildingIndex: Int, floorIndex: Int, roomIndex: Int) {
        buildings[buildingIndex].floors[floorIndex].rooms.remove(at: roomIndex)
        // Se necessario, gestire la rimozione della stanza dalla connessione
        saveBuildings(buildings)
    }
    
    @MainActor func renameRoomInFloor(at buildingIndex: Int, floorIndex: Int, roomIndex: Int, newName: String) {
        buildings[buildingIndex].floors[floorIndex].rooms[roomIndex].roomName = newName
        saveBuildings(buildings)
    }
    
    // Interfaccia per i metodi di Connection
    
    @MainActor func createConnection(in buildingIndex: Int, room1: Room, room2: Room) {
        buildings[buildingIndex].connections.createConnection(room1: room1, room2: room2)
        saveBuildings(buildings)
    }
    
    @MainActor func deleteConnection(in buildingIndex: Int, room1: Room, room2: Room) {
        buildings[buildingIndex].connections.deleteConnection(room1: room1, room2: room2)
        saveBuildings(buildings)
    }
    
    func getConnection(in buildingIndex: Int, room1: Room, room2: Room) -> Bool {
        return buildings[buildingIndex].connections.getConnection(room1: room1, room2: room2)
    }
    
    func getConnectedRooms(in buildingIndex: Int, room: Room) -> [Room] {
        return buildings[buildingIndex].connections.getConnectedRooms(room: room)
    }
    
    func loadBuildings() -> [Building] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let buildingsURL = documentsDirectory.appendingPathComponent("buildings.json")
        
        do {
            let data = try Data(contentsOf: buildingsURL)
            let decoder = JSONDecoder()
            // decoder.dateDecodingStrategy = .iso8601 // Commentato perché la tua data è una stringa
            return try decoder.decode([Building].self, from: data)
        } catch {
            print("Errore nel caricamento dei buildings: \(error)")
            return []
        }
    }
    
    @MainActor func saveBuildings(_ buildings: [Building]) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let buildingsURL = documentsDirectory.appendingPathComponent("buildings.json")
        
        do {
            let encoder = JSONEncoder()
            // encoder.dateEncodingStrategy = .iso8601 // Commentato perché la tua data è una stringa
            let data = try encoder.encode(buildings)
            try data.write(to: buildingsURL)
        } catch {
            print("Errore nel salvataggio dei buildings: \(error)")
        }
    }
}

