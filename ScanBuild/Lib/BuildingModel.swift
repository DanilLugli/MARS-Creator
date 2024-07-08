import Foundation

class BuildingModel: ObservableObject {
    
    private static var INSTANCE: BuildingModel?
    
    private static var SCAN_BUILD_ROOT: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("ScanBuild")
    }
    
    public static func getInstance() -> BuildingModel {
        if self.INSTANCE == nil {
            self.INSTANCE = BuildingModel()
        }
        return self.INSTANCE!
    }
    
    private static let LOGGER = Logger(tag: String(describing: BuildingModel.self))
    
    private let fileManager = FileManager.default
    
    @Published private var buildings: [Building] = []
    
    @Published private var floors: [UUID : [Floor]] = [:]
    
    @Published private var rooms: [UUID : [Room]] = [:]
    
    @Published private var transitionZones: [UUID : [TransitionZone]] = [:]
    
    
    private init() {
        let scanBuildDirectory = BuildingModel.SCAN_BUILD_ROOT
        
        // Crea la directory "ScanBuild" nella directory dei documenti se non esiste.
        if !self.fileManager.fileExists(atPath: scanBuildDirectory.path) {
            do {
                try self.fileManager.createDirectory(at: scanBuildDirectory, withIntermediateDirectories: true, attributes: nil)
                BuildingModel.LOGGER.log("Created directory at \(scanBuildDirectory.path)")
            } catch {
                BuildingModel.LOGGER.log("An error occurred while creating the \(scanBuildDirectory.path) directory. Reason: \(error)")
            }
        } else {
            BuildingModel.LOGGER.log("Directory already exists at \(scanBuildDirectory.path)")
        }
        
        // Carica gli edifici dal file JSON
        //self.buildings = loadBuildings()
    }
    
    @MainActor func initTryData() -> UUID {
        if !self.buildings.isEmpty {
            return self.getBuildings()[0].id
        }
        
        for i in 1...10 {
            let building = Building(name: "Building \(i)", date: "Date \(i)", fileURL: URL(fileURLWithPath: ""))
            self.addBuilding(building: building)
            
            // Aggiungi 5 piani al primo edificio
            for j in 1...5 {
                let floor = Floor(name: "Floor \(i)_\(j)", fileURL: URL(fileURLWithPath: ""), idBuilding: self.getBuildings()[0].id, date: "Date \(j)")
                self.addFloorToBuilding(buildingId: building.id, floor: floor)
                
                for k in 1...5 {
                    
                    let room = Room(roomName: "Room \(k)>\(i)_\(j)", floorName: floor.name, date: "Date \(k)", idFloor: floor.id, fileURL: URL(fileURLWithPath: ""), associationMatrix: [[]], referenceMarkers: [])
                    
                    self.addRoomToFloor(floorId: floor.id, room: room)
                    for z in 1...2 {
                        let xMin = Double.random(in: 0...10)
                        let xMax = xMin + Double.random(in: 1...5)
                        let yMin = Double.random(in: 0...10)
                        let yMax = yMin + Double.random(in: 1...5)
                        let transitionZone = TransitionZone(name: "Scala \(z)", xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax)
                        self.addTransitionZone(roomId: room.id, transitionZone: transitionZone)
                    }
                }
            }
            
            let floors = self.getFloors(byBuildingId: building.id)
            for q in 0..<3 {
                let zone1 = self.getTransitionZones(byRoomId: self.getRooms(byFloorId: floors[q].id)[0].id)[0]
                let zone2 = self.getTransitionZones(byRoomId: self.getRooms(byFloorId: floors[q+1].id)[0].id)[0]
                self.createConnection(buildingId: building.id, zone1: zone1, zone2: zone2)
            }
        }
        
        return self.getBuildings()[0].id
    }
    
    func getBuildings() -> [Building] {
        return Array(buildings)
    }
    
    func getBuildingById(_ id: UUID) -> Building? {
        return buildings.first { $0.id == id }
    }
    
    func getFloorById(_ id: UUID) -> Floor? {
        for (_, floorArray) in floors {
            if let floor = floorArray.first(where: { $0.id == id }) {
                return floor
            }
        }
        return nil
    }
    
    func getRoomById(_ id: UUID) -> Room? {
        for (_, roomArray) in rooms {
            if let room = roomArray.first(where: { $0.id == id }) {
                return room
            }
        }
        return nil
    }
    
    func getTransitionZoneById(_ id: UUID) -> TransitionZone? {
        for (_, transitionZonesArray) in transitionZones {
            if let transitionZone = transitionZonesArray.first(where: { $0.id == id }) {
                return transitionZone
            }
        }
        return nil
    }
    
    func getFloors(byBuildingId buildingId: UUID) -> [Floor] {
        return Array(floors[buildingId] ?? [])
    }
    
    func getRooms(byFloorId floorId: UUID) -> [Room] {
        return Array(rooms[floorId] ?? [])
    }
    
    func getTransitionZones(byRoomId roomId: UUID) -> [TransitionZone] {
        return Array(transitionZones[roomId] ?? [])
    }
    
    func listConnections(buildingId: UUID) -> [FloorBridge] {
        return Array(self.getBuildingById(buildingId)?.connections.listConnections() ?? [])
    }
    
    @MainActor func addBuilding(building: Building) {
        buildings.append(building)
        //saveBuildings(buildings)
    }
    
    @MainActor func deleteBuilding(id: UUID) {
        buildings.removeAll { $0.id == id }
        floors.removeValue(forKey: id)
        // Rimuovere tutte le stanze e le zone di transizione associate ai piani dell'edificio eliminato
        for floor in floors[id] ?? [] {
            rooms.removeValue(forKey: floor.id)
            transitionZones.removeValue(forKey: floor.id)
        }
        //saveBuildings(buildings)
    }
    
    @MainActor func renameBuilding(id: UUID, newName: String) {
        guard let index = buildings.firstIndex(where: { $0.id == id }) else { return }
        buildings[index].name = newName
        //saveBuildings(buildings)
    }
    
    @MainActor func addFloorToBuilding(buildingId: UUID, floor: Floor) {
        floors[buildingId, default: []].append(floor)
        //saveBuildings(buildings)
    }
    
    @MainActor func addTransitionZone(roomId: UUID, transitionZone: TransitionZone) {
        self.transitionZones[roomId, default: []].append(transitionZone)
    }
    
    @MainActor func deleteFloorFromBuilding(buildingId: UUID, floorId: UUID) {
        floors[buildingId]?.removeAll { $0.id == floorId }
        rooms.removeValue(forKey: floorId)
        transitionZones.removeValue(forKey: floorId)
        //saveBuildings(buildings)
    }
    
    @MainActor func renameFloorInBuilding(buildingId: UUID, floorId: UUID, newName: String) {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }),
              let floorIndex = floors[buildingId]?.firstIndex(where: { $0.id == floorId }) else { return }
        floors[buildingId]?[floorIndex].name = newName
        //saveBuildings(buildings)
    }
    
    @MainActor func saveFloorOfBuilding(buildingId: UUID, floorId: UUID, floor: Floor) {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }),
              let floorIndex = floors[buildingId]?.firstIndex(where: { $0.id == floorId }) else { return }
        floors[buildingId]?[floorIndex] = floor
        //saveBuildings(buildings)
    }
    
    @MainActor func addRoomToFloor(floorId: UUID, room: Room) {
        rooms[floorId, default: []].append(room)
        //saveBuildings(buildings)
    }
    
    @MainActor func deleteRoomFromFloor(floorId: UUID, roomId: UUID) {
        rooms[floorId]?.removeAll { $0.id == roomId }
        //saveBuildings(buildings)
    }
    
    @MainActor func renameRoomInFloor(floorId: UUID, roomId: UUID, newName: String) {
        guard let roomIndex = rooms[floorId]?.firstIndex(where: { $0.id == roomId }) else { return }
        rooms[floorId]?[roomIndex].roomName = newName
        //saveBuildings(buildings)
    }
    
    // Interfaccia per i metodi di Connection
    
    @MainActor func createConnection(buildingId: UUID, zone1: TransitionZone, zone2: TransitionZone) {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }) else { return }
        
        buildings[buildingIndex].connections.addZoneToConnection(zone: zone1)
        buildings[buildingIndex].connections.addZoneToConnection(zone: zone2)
        
        buildings[buildingIndex].connections.createConnection(zone1: zone1, zone2: zone2)
        //saveBuildings(buildings)
    }
    
    @MainActor func deleteConnection(buildingId: UUID, zone1: TransitionZone, zone2: TransitionZone) {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }) else { return }
        buildings[buildingIndex].connections.deleteConnection(zone1: zone1, zone2: zone2)
        //saveBuildings(buildings)
    }
    
    func getConnection(buildingId: UUID, zone1: TransitionZone, zone2: TransitionZone) -> Bool {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }) else { return false }
        return buildings[buildingIndex].connections.getConnection(zone1: zone1, zone2: zone2)
    }
    
    func getConnectedZones(buildingId: UUID, zone: TransitionZone) -> [TransitionZone] {
        guard let buildingIndex = buildings.firstIndex(where: { $0.id == buildingId }) else { return [] }
        return buildings[buildingIndex].connections.getConnectedZones(zone: zone)
    }
    
    //    func loadBuildings() -> [Building] {
    //        let buildingsURL = BuildingModel.SCAN_BUILD_ROOT.appendingPathComponent(“buildings.json”)
    //
    //        do {
    //            let data = try Data(contentsOf: buildingsURL)
    //            let decoder = JSONDecoder()
    //            // decoder.dateDecodingStrategy = .iso8601 // Commentato perché la tua data è una stringa
    //            return try decoder.decode([Building].self, from: data)
    //        } catch {
    //            print(“Errore nel caricamento dei buildings: (error)”)
    //            return []
    //        }
    //    }
    //
    //    @MainActor func saveBuildings(_ buildings: [Building]) {
    //        let buildingsURL = BuildingModel.SCAN_BUILD_ROOT.appendingPathComponent(“buildings.json”)
    //
    //        do {
    //            let encoder = JSONEncoder()
    //            // encoder.dateEncodingStrategy = .iso8601 // Commentato perché la tua data è una stringa
    //            let data = try encoder.encode(buildings)
    //            try data.write(to: buildingsURL)
    //        } catch {
    //            print(“Errore nel salvataggio dei buildings: (error)”)
    //        }
    //    }
    }
