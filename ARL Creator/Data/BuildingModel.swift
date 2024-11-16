import Foundation
import ARKit
import SceneKit
import SwiftUI

class BuildingModel: ObservableObject {
    
    private static var _instance: BuildingModel?
    private static let LOGGER = Logger(tag: String(describing: BuildingModel.self))
    
    static var SCANBUILD_ROOT: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("ARLCreator")
    }
    static let FLOOR_DATA_FOLDER = "Data"
    static let FLOOR_ROOMS_FOLDER = "Rooms"
    static let ASSASSOCIATION_MATRIX_FILE = ""
    
    @Published var buildings: [Building]
    
    private init() {
        self.buildings = []
        Task {
            await loadBuildings()
        }
    }
    
    @MainActor func loadBuildings(){
        do {
            try loadBuildingsFromRoot()
        } catch {
            BuildingModel.LOGGER.log("Errore durante il caricamento degli edifici: \(error)")
        }
    }
    
    static func getInstance() -> BuildingModel {
        if _instance == nil {
            _instance = BuildingModel()
        }
        return _instance!
    }
 
    func initTryData() -> Building {
        self.buildings = []

        for i in 1...3 {
            let building = Building(name: "Building \(i)", lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: ""))

            for j in 1...5 {
                let floor = Floor(_name: "Floor \(j)", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _planimetryRooms: SCNViewMapContainer(), _associationMatrix: [String : RotoTraslationMatrix](), _rooms: [], _sceneObjects: nil, _scene: nil, _sceneConfiguration: nil, _floorURL: URL(fileURLWithPath: ""))
                
                for k in 1...5 {

                    let room = Room(_name: "Room \(k)", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _referenceMarkers: [], _transitionZones: [], _scene: nil, _sceneObjects: [], _roomURL: URL(fileURLWithPath: ""))

                    for z in 1...2 {
                        let transitionZone = TransitionZone(name: "Scala \(z)", connection: [])
                        
                        // Creiamo 3 connessioni casuali per ogni transitionZone
                        for _ in 1...3 {
                            let randomTargetFloor = "Floor \(Int.random(in: 1...5))"
                            let randomTargetRoom = "Room \(Int.random(in: 1...5))"
                            let randomTargetTransitionZone = "TZ \(Int.random(in: 1...3))"
                            
                            let connection = AdjacentFloorsConnection(
                                name: "Connection to \(randomTargetRoom)",
                                fromTransitionZone: randomTargetTransitionZone,
                                targetFloor: randomTargetFloor,
                                targetRoom: randomTargetRoom,
                                targetTransitionZone: randomTargetTransitionZone
                            )
                            
                            // Aggiungiamo la connessione alla lista di connessioni della TransitionZone
                            transitionZone.connection?.append(connection)
                        }

                        // Aggiungi la TransitionZone alla Room
                        room.addTransitionZone(transitionZone: transitionZone)
                    }
                    floor.addRoom(room: room)
                }
                building.addFloor(floor: floor)
            }
            self.addBuilding(building: building)
        }
        
        return self.getBuildings()[0]
    }
    
    @MainActor func loadBuildingsFromRoot() throws {
    let fileManager = FileManager.default
    
    if !fileManager.fileExists(atPath: BuildingModel.SCANBUILD_ROOT.path) {
        
        do {
            try fileManager.createDirectory(at: BuildingModel.SCANBUILD_ROOT, withIntermediateDirectories: true, attributes: nil)
            print("Cartella root creata: \(BuildingModel.SCANBUILD_ROOT.path)")
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 1, userInfo: [NSLocalizedDescriptionKey: "Errore durante la creazione della cartella root: \(error)"])
        }
    }
    
    let buildingURLs = try fileManager.contentsOfDirectory(at: BuildingModel.SCANBUILD_ROOT, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
    print(buildingURLs)
    
    for buildingURL in buildingURLs {
        print(buildingURL)
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: buildingURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            let attributes = try fileManager.attributesOfItem(atPath: buildingURL.path)
            if let lastModifiedDate = attributes[.modificationDate] as? Date {
                let floors = try loadFloors(from: buildingURL)
                let building = Building(name: buildingURL.lastPathComponent, lastUpdate: lastModifiedDate, floors: floors, buildingURL: buildingURL)
                addBuilding(building: building)
            }
        }
    }
}
    
    @MainActor func loadFloors(from buildingURL: URL) throws -> [Floor] {
        let fileManager = FileManager.default
        let floorURLs = try fileManager.contentsOfDirectory(at: buildingURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        
        var floors: [Floor] = []
        for floorURL in floorURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: floorURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let attributes = try fileManager.attributesOfItem(atPath: floorURL.path)
                if let lastModifiedDate = attributes[.modificationDate] as? Date {
                    
                    let floorDataURL = floorURL
                    
                    let sceneObjects: [SCNNode] = []
                    let scene: SCNScene? = nil
                    let sceneConfiguration: SCNScene? = nil
                    var associationMatrix: [String : RotoTraslationMatrix]?
                    let planimetry: SCNViewContainer = SCNViewContainer()
                    let planimetryRooms: SCNViewMapContainer = SCNViewMapContainer()
                    
                    if fileManager.fileExists(atPath: floorDataURL.path) {
                        _ = try fileManager.contentsOfDirectory(at: floorDataURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

                    }
                    
                    let associationMatrixURL = floorURL.appendingPathComponent("\(floorURL.lastPathComponent).json")
                    if fileManager.fileExists(atPath: associationMatrixURL.path) {
                        if let loadedMatrix = loadRoomPositionFromJson(from: associationMatrixURL) {
                            associationMatrix = loadedMatrix
                            print("Matrix loaded for floor \(floorURL.lastPathComponent): \(String(describing: associationMatrix))\n")
                        } else {
                            print("Failed to load RotoTraslationMatrix from JSON file for floor \(floorURL.lastPathComponent)")
                        }
                    }
                    
                    
                    var rooms: [Room] = []
                    
                    
                    let floor = Floor(_name: floorURL.lastPathComponent,
                                      _lastUpdate: lastModifiedDate,
                                      _planimetry: planimetry,
                                      _planimetryRooms: planimetryRooms,
                                      _associationMatrix: associationMatrix ?? [:],
                                      _rooms: rooms,
                                      _sceneObjects: sceneObjects,
                                      _scene: scene,
                                      _sceneConfiguration: sceneConfiguration,
                                      _floorURL: floorURL
                    )
                    
                    rooms = try loadRooms(from: floorURL, floor: floor)
                    floor.rooms = rooms
                    
                    var floorRooms: [Room] = []
                    rooms.forEach { room in
                        floorRooms.append(room)
                    }
                    
                    if FileManager.default.fileExists(atPath: floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floorURL.lastPathComponent).usdz").path){
                        
                        let usdzURL = floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
                        floor.scene = try SCNScene(url: usdzURL)
                        
                        floor.planimetry.loadFloorPlanimetry(borders: true, floor: floor)
                        
                        _ = floor.rooms.map { $0.name }
                        
                        var seenNodeNames = Set<String>()
                        
                        print("PRE_CARICAMENTO NODI \(floor.name)")
                        
                        floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
                            if let nodeName = n.name {
                                if seenNodeNames.contains(nodeName) {
                                    print("NODE ALREADY CREATED: \(nodeName)")
                                    return false
                                }

                                guard n.geometry != nil else {
                                    print("NODE WITHOUT GEOMETRY: \(nodeName)")
                                    return false
                                }

                                let isValidNode = nodeName != "Room" &&
                                                  nodeName != "Geom" &&
                                                  !nodeName.hasSuffix("_grp") &&
                                                  !nodeName.hasPrefix("unidentified") &&
                                                  !(nodeName.first?.isNumber ?? false) &&
                                                  !nodeName.hasPrefix("_")

                                if isValidNode {
                                    seenNodeNames.insert(nodeName)
                                    print("VALID MESH NODE ADDED: \(nodeName)")
                                    return true
                                }
                            }
                            
                            return false
                        }).sorted(by: {
                            ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                        })
                        ?? []
                    }
                    
                    
                    floor.planimetryRooms.handler.loadRoomsMaps(
                        floor: floor,
                        rooms: floorRooms,
                        borders: true
                    )
                    
                    floors.append(floor)
                }
            }
        }
        return floors
    }
    
    private func loadRooms(from floorURL: URL, floor: Floor) throws -> [Room] {
        let fileManager = FileManager.default
        
        let roomsDirectoryURL = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        let roomURLs = try fileManager.contentsOfDirectory(at: roomsDirectoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        
        var rooms: [Room] = []
        for roomURL in roomURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: roomURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let attributes = try fileManager.attributesOfItem(atPath: roomURL.path)
                if let lastModifiedDate = attributes[.modificationDate] as? Date {
                    
                    var referenceMarkers: [ReferenceMarker] = []
                    let transitionZones: [TransitionZone] = []
                    let scene: SCNScene? = nil
                    let sceneObjects: [SCNNode] = []
                    let planimetry: SCNViewContainer = SCNViewContainer()

                    let referenceMarkerURL = roomURL.appendingPathComponent("ReferenceMarker")

                    if fileManager.fileExists(atPath: referenceMarkerURL.path) {
                        let referenceMarkerContents = try fileManager.contentsOfDirectory(at: referenceMarkerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
                        // Percorso al file JSON dei marker
                        let markerDataURL = referenceMarkerURL.appendingPathComponent("Marker Data.json")
                        
                        // Carica i dati dal JSON solo una volta
                        var markersData: [String: ReferenceMarker.MarkerData] = [:]
                        if fileManager.fileExists(atPath: markerDataURL.path) {
                            let jsonData = try Data(contentsOf: markerDataURL)
                            markersData = try JSONDecoder().decode([String: ReferenceMarker.MarkerData].self, from: jsonData)
                            print("\n\n\nMARKERS DATA")
                            print(markersData)
                        }
                        
                        for fileURL in referenceMarkerContents {
                            if fileURL.pathExtension.lowercased() == "jpg" || fileURL.pathExtension.lowercased() == "png" || fileURL.pathExtension.lowercased() == "jpeg" {
                                // Nome e percorso immagine
                                let imageName = fileURL.deletingPathExtension().lastPathComponent
                                let imagePath = fileURL
                                
                                // Recupera i dati dal JSON (nome e larghezza) se disponibili
                                let coordinates = Coordinates(x: Float(Double.random(in: -100...100)), y: Float(Double.random(in: -100...100))) // Coordinate di esempio
                                let rmUML = URL(fileURLWithPath: "")
                                let markerWidth = markersData[imageName]?.width ?? 0.0 // Recupera la larghezza dal JSON se esiste
                                let markerName = markersData[imageName]?.name ?? imageName // Recupera il nome dal JSON o usa il nome dell'immagine
                                
                                // Crea un nuovo ReferenceMarker con i dati caricati dal JSON
                                let newMarker = ReferenceMarker(
                                    _imagePath: imagePath,
                                    _imageName: markerName,
                                    _coordinates: coordinates,
                                    _rmUML: rmUML,
                                    _physicalWidth: markerWidth
                                )
                                
                                referenceMarkers.append(newMarker)
                            }
                        }
                    }
                    
                    let room = Room(
                        _name: roomURL.lastPathComponent,
                        _lastUpdate: lastModifiedDate,
                        _planimetry: planimetry,
                        _referenceMarkers: referenceMarkers,
                        _transitionZones: transitionZones,
                        _scene: scene,
                        _sceneObjects: sceneObjects,
                        _roomURL: roomURL,
                        parentFloor: floor
                    )

                    if fileManager.fileExists(atPath: roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path) {
                        let usdzURL = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                        room.scene = try SCNScene(url: usdzURL)
                        
                        var seenNodeNames = Set<String>()
                        print("PRE_CARICAMENTO NODI \(room.name)")
                        room.sceneObjects = room.scene?.rootNode.childNodes(passingTest: { n, _ in
                            if let nodeName = n.name {
                                if seenNodeNames.contains(nodeName) {
                                    print("NODE ALREADY CREATED: \(nodeName)")
                                    return false
                                }
                                guard n.geometry != nil else {
                                    print("NODE WITHOUT GEOMETRY: \(nodeName)")
                                    return false
                                }
                                let isValidNode = nodeName != "Room" &&
                                                  nodeName != "Geom" &&
                                                  !nodeName.hasSuffix("_grp") &&
                                                  !nodeName.hasPrefix("unidentified") &&
                                                  !(nodeName.first?.isNumber ?? false) &&
                                                  !nodeName.hasPrefix("_")

                                if isValidNode {
                                    seenNodeNames.insert(nodeName)
                                    print("VALID MESH NODE ADDED: \(nodeName)")
                                    return true
                                }
                            }
                            return false
                        }).sorted(by: { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }) ?? []
                    } else {
                        print("File .usdz for \(room.name) planimetry is not available.")
                    }
                    
                    room.planimetry.loadRoomPlanimetry(room: room, borders: true)
                    rooms.append(room)
                }
            }
        }
        return rooms
    }
    
    func getBuildings() -> [Building] {
        return buildings
    }
    
    func getBuilding(_ building: Building) -> Building? {
        return buildings.first { $0.id == building.id }
    }
    
    func addBuilding(building: Building) {
        buildings.append(building)
        
        let buildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(building.name)
        do {
            try FileManager.default.createDirectory(at: buildingURL, withIntermediateDirectories: true, attributes: nil)
            building.buildingURL = buildingURL
            print("Folder created at: \(buildingURL.path)")
        } catch {
            print("Error creating folder for building \(building.name): \(error)")
        }
    }
    
    @MainActor func renameBuilding(building: Building, newName: String) throws {
        let fileManager = FileManager.default
        let oldBuildingURL = building.buildingURL
        
        building.name = newName
        
        let newBuildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(building.name)
        building.buildingURL = newBuildingURL
        
        guard !fileManager.fileExists(atPath: newBuildingURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già un building con il nome \(newName)"])
        }

        do {
            try fileManager.moveItem(at: oldBuildingURL, to: newBuildingURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella del building: \(error.localizedDescription)"])
        }

        for floor in building.floors {
            floor.floorURL = newBuildingURL.appendingPathComponent(floor.name)
            print("NEW FLOOR URL: \(floor.floorURL)")
            
            if fileManager.fileExists(atPath: floor.floorURL.path) {
                print("Floor directory exists at: \(floor.floorURL.path)")
            } else {
                print("Floor directory does not exist at: \(floor.floorURL.path)")
            }

            for room in floor.rooms {
                room.roomURL = floor.floorURL.appendingPathComponent("Rooms").appendingPathComponent(room.name)
                print("NEW ROOM URL: \(room.roomURL)")

                if fileManager.fileExists(atPath: room.roomURL.path) {
                    print("Room directory exists at: \(room.roomURL.path)")
                } else {
                    print("Room directory does not exist at: \(room.roomURL.path)")
                }

                let mapUsdzURL = room.roomURL.appendingPathComponent("MapUsdz")
                if fileManager.fileExists(atPath: mapUsdzURL.path) {
                    print("MapUsdz file found at: \(mapUsdzURL.path)")
                } else {
                    print("MapUsdz file not found at: \(mapUsdzURL.path)")
                }
            }
        }

        BuildingModel.LOGGER.log("Building rinominato da \(building.name) a \(newName)")
    }
    
    func deleteBuilding(building: Building) {
        
        buildings.removeAll { $0.id == building.id }

        let buildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(building.name)

        do {
            try FileManager.default.removeItem(at: buildingURL)
            print("Folder deleted at: \(buildingURL.path)")
        } catch {
            print("Error deleting folder for building \(building.name): \(error.localizedDescription)")
        }
    }
}
