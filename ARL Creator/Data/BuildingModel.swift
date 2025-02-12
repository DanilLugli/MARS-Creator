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
            loadBuildings()
        }
    }
    
    func loadBuildings() {
        Task {
            do {
                try await loadBuildingsFromRoot()
            } catch {
                BuildingModel.LOGGER.log("Error upload building: \(error)")
            }
        }
    }
    
    static func getInstance() -> BuildingModel {
        if _instance == nil {
            _instance = BuildingModel()
        }
        return _instance!
    }
    
    func loadBuildingsFromRoot() async throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: BuildingModel.SCANBUILD_ROOT.path) {
            try await Task {
                try fileManager.createDirectory(at: BuildingModel.SCANBUILD_ROOT, withIntermediateDirectories: true, attributes: nil)
            }.value
        }
        
        //    if !fileManager.fileExists(atPath: BuildingModel.SCANBUILD_ROOT.path) {
        //
        //
        //        do {
        //            try fileManager.createDirectory(at: BuildingModel.SCANBUILD_ROOT, withIntermediateDirectories: true, attributes: nil)
        //        } catch {
        //            throw NSError(domain: "com.example.ScanBuild", code: 1, userInfo: [NSLocalizedDescriptionKey: "Errore durante la creazione della cartella root: \(error)"])
        //        }
        //    }
        
        let buildingURLs = try await Task {
            try fileManager.contentsOfDirectory(at: BuildingModel.SCANBUILD_ROOT, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        }.value
        
        for buildingURL in buildingURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: buildingURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let attributes = try fileManager.attributesOfItem(atPath: buildingURL.path)
                if let lastModifiedDate = attributes[.modificationDate] as? Date {
                    
                    let floors = try await loadFloors(from: buildingURL)
                    let building = Building(name: buildingURL.lastPathComponent, lastUpdate: lastModifiedDate, floors: floors, buildingURL: buildingURL)
                    
                    await MainActor.run {
                        self.addBuilding(building: building)
                    }
                }
            }
        }
    }
    
    @MainActor
    func loadFloors(from buildingURL: URL) throws -> [Floor] {
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

                    var associationMatrix: [String : RotoTraslationMatrix]?
                    let planimetry: SCNViewContainer = SCNViewContainer()
                    let planimetryRooms: SCNViewMapContainer = SCNViewMapContainer()
                    
                    if fileManager.fileExists(atPath: floorDataURL.path) {
                        _ = try fileManager.contentsOfDirectory(at: floorDataURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

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
                                      _floorURL: floorURL
                    )
                   
                    rooms = try loadRooms(from: floorURL, floor: floor)
                    floor.rooms = rooms
                    
                    let associationMatrixURL = floorURL.appendingPathComponent("\(floorURL.lastPathComponent).json")
                    if fileManager.fileExists(atPath: associationMatrixURL.path),
                       let loadedMatrix = loadRoomPositionFromJson(from: associationMatrixURL, for: floor) {
                        floor._associationMatrix = loadedMatrix

                        // Debug: stampa il contenuto dell'association matrix
                        print("BUILDING: \(buildingURL.lastPathComponent)")
                        print("Loaded Association Matrix for floor \(floorURL.lastPathComponent):")
                        for (roomName, matrix) in floor._associationMatrix {
                            print("Room: \(roomName)")
                            print("Translation Matrix:")
                            for i in 0..<4 {
                                let row = "[\(matrix.translation[i,0]), \(matrix.translation[i,1]), \(matrix.translation[i,2]), \(matrix.translation[i,3])]"
                                print(row)
                            }
                            print("R_Y Matrix:")
                            for i in 0..<4 {
                                let row = "[\(matrix.r_Y[i,0]), \(matrix.r_Y[i,1]), \(matrix.r_Y[i,2]), \(matrix.r_Y[i,3])]"
                                print(row)
                            }
                        }
                    } else {
                        print("Failed to load RotoTraslationMatrix from JSON file for floor \(floorURL.lastPathComponent)")
                    }
                    
                    let floorRooms: [Room] = floor.rooms.map {$0}
                    
                    if FileManager.default.fileExists(atPath: floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floorURL.lastPathComponent).usdz").path){
                        
                        let usdzURL = floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
                        
                        floor.scene = try SCNScene(url: usdzURL)
                        
                        floor.planimetry = SCNViewContainer(empty: true)
                        
                        floor.planimetryRooms.handler.loadRoomsMaps(
                            floor: floor,
                            rooms: floorRooms
                        )
                        
                        _ = floor.rooms.map { $0.name }
                        
                        var seenNodeNames = Set<String>()
                        
                        floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
                            if let nodeName = n.name {
                                if seenNodeNames.contains(nodeName) {
                                    return false
                                }

                                guard n.geometry != nil else {
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
                                    return true
                                }
                            }
                            
                            return false
                        }).sorted(by: {
                            ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                        })
                        ?? []
                    }
                    
                    floors.append(floor)
                }
            }
        }
        return floors
    }
    
    @MainActor
    func loadRooms(from floorURL: URL, floor: Floor) throws -> [Room] {
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
                        do {
                            let referenceMarkerContents = try fileManager.contentsOfDirectory(at: referenceMarkerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                            let markerDataURL = referenceMarkerURL.appendingPathComponent("Marker Data.json")

                            var markersData: [String: ReferenceMarker.MarkerData] = [:]

                            // Se il file JSON non esiste, lo creiamo vuoto
                            if !fileManager.fileExists(atPath: markerDataURL.path) {
                                let emptyData = "{}".data(using: .utf8)
                                fileManager.createFile(atPath: markerDataURL.path, contents: emptyData, attributes: nil)
                                print("✅ Creato un nuovo file vuoto per i marker.")
                            }

                            // Carichiamo i dati se il file esiste
                            if fileManager.fileExists(atPath: markerDataURL.path) {
                                let jsonData = try Data(contentsOf: markerDataURL)
                                markersData = try JSONDecoder().decode([String: ReferenceMarker.MarkerData].self, from: jsonData)
                            }

                            var updatedMarkersData = markersData // Creiamo una copia per aggiornare i dati

                            for fileURL in referenceMarkerContents {
                                if ["jpg", "png", "jpeg"].contains(fileURL.pathExtension.lowercased()) {
                                    let imageName = fileURL.deletingPathExtension().lastPathComponent
                                    let imagePath = fileURL

                                    // Se mancano le coordinate, le impostiamo a 0,0,0
                                    let coordinatesDict = markersData[imageName]?.coordinates ?? ["x": 0.0, "y": 0.0, "z": 0.0]
                                    
                                    if markersData[imageName]?.coordinates == nil {
                                        print("⚠️ Coordinate mancanti per '\(imageName)'. Aggiungendo (0,0,0) nel JSON.")
                                        updatedMarkersData[imageName] = ReferenceMarker.MarkerData(
                                            name: markersData[imageName]?.name ?? imageName,
                                            width: markersData[imageName]?.width ?? 0.0,
                                            coordinates: ["x": 0.0, "y": 0.0, "z": 0.0] // ✅ Aggiunto automaticamente
                                        )
                                    }

                                    let coordinates = simd_float3.fromDictionary(coordinatesDict)
                                    let rmUML = URL(fileURLWithPath: "")
                                    let markerWidth = markersData[imageName]?.width ?? 0.0
                                    let markerName = markersData[imageName]?.name ?? imageName

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

                            // ✅ Salviamo i dati aggiornati nel JSON se ci sono stati cambiamenti
                            if updatedMarkersData != markersData {
                                let updatedJsonData = try JSONEncoder().encode(updatedMarkersData)
                                try updatedJsonData.write(to: markerDataURL)
                                print("✅ Dati aggiornati e salvati nel JSON (coordinate aggiunte dove mancavano).")
                            } else {
                                print("✅ Nessuna modifica necessaria, tutti i dati erano già completi.")
                            }

                        } catch {
                            print("❌ Errore nella gestione dei file dei marker: \(error)")
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
                        room.sceneObjects = room.scene?.rootNode.childNodes(passingTest: { n, _ in
                            if let nodeName = n.name {
                                if seenNodeNames.contains(nodeName) {
                                    return false
                                }
                                guard n.geometry != nil else {
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
                                    return true
                                }
                            }
                            return false
                        }).sorted(by: { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }) ?? []
                    } else {
                        print("File .usdz for \(room.name) planimetry is not available.")
                    }
                    
                    room.planimetry = SCNViewContainer(empty: true)
                    
                    let connectionFileURL = roomURL.appendingPathComponent("Connection.json")
                    if fileManager.fileExists(atPath: connectionFileURL.path) {
                        do {
                            let jsonData = try Data(contentsOf: connectionFileURL)
                            let connections = try JSONDecoder().decode([AdjacentFloorsConnection].self, from: jsonData)
                            room.connections.append(contentsOf: connections)
                        } catch {
                            print("Error loading connections for room \(room.name): \(error)")
                        }
                    } else {
                        do {
                            let emptyConnections: [AdjacentFloorsConnection] = []
                            let jsonData = try JSONEncoder().encode(emptyConnections)
                            try jsonData.write(to: connectionFileURL)
                        } catch {
                            print("Error creating Connection.json for room \(room.name): \(error)")
                        }
                    }
                    
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
        } catch {
            print("Error creating folder for building \(building.name): \(error)")
        }
    }
    
    @MainActor
    func renameBuilding(building: Building, newName: String) throws {
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

        BuildingModel.LOGGER.log("Building rinominato da \(building.name) a \(newName)")
    }
    
    func deleteBuilding(building: Building) {
        
        buildings.removeAll { $0.id == building.id }

        let buildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(building.name)

        do {
            try FileManager.default.removeItem(at: buildingURL)
        } catch {
            print("Error deleting folder for building \(building.name): \(error.localizedDescription)")
        }
    }
    
    func initTryData() -> Building {
        self.buildings = []

        for i in 1...3 {
            let building = Building(name: "Building \(i)", lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: ""))

            for j in 1...5 {
                let floor = Floor(_name: "Floor \(j)", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _planimetryRooms: SCNViewMapContainer(), _associationMatrix: [String : RotoTraslationMatrix](), _rooms: [], _sceneObjects: nil, _scene: nil, _floorURL: URL(fileURLWithPath: ""))
                
                for k in 1...5 {

                    let room = Room(_name: "Room \(k)", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _referenceMarkers: [], _transitionZones: [], _scene: nil, _sceneObjects: [], _roomURL: URL(fileURLWithPath: ""))

                    for z in 1...2 {
                        let transitionZone = TransitionZone(name: "Scala \(z)", connection: [])
                        
                        // Creiamo 3 connessioni casuali per ogni transitionZone
                        for _ in 1...3 {
                            let randomTargetFloor = "Floor \(Int.random(in: 1...5))"
                            let randomTargetRoom = "Room \(Int.random(in: 1...5))"
                            _ = "TZ \(Int.random(in: 1...3))"
                            let randomAltitude = Float.random(in: 0...100)
                            
                            let connection = AdjacentFloorsConnection(
                                name: "Connection to \(randomTargetRoom)",
                                targetFloor: randomTargetFloor,
                                targetRoom: randomTargetRoom,
                                altitude: randomAltitude
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
}
