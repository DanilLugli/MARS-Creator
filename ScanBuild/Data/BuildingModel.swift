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
    
    @MainActor
    func loadBuildings() async {
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

                    let room = Room(_name: "Room \(k)", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _referenceMarkers: [], _transitionZones: [], _sceneObjects: [], _roomURL: URL(fileURLWithPath: ""))
                    
                    for z in 1...2 {
                        _ = Float.random(in: 0...10)
                        _ = Float.random(in: 0...10)
                        let transitionZone = TransitionZone(name: "Scala \(z)", connection: nil)
                        do {
                             room.addTransitionZone(transitionZone: transitionZone)
                        }
                    }
                    floor.addRoom(room: room)
                }
                building.addFloor(floor: floor)
            }
            self.addBuilding(building: building)
        }
        
        return self.getBuildings()[0]
    }
    
    @MainActor
    func loadBuildingsFromRoot() throws {
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
                    
                    var sceneObjects: [SCNNode] = []
                    var scene: SCNScene? = nil
                    var sceneConfiguration: SCNScene? = nil
                    var associationMatrix: [String : RotoTraslationMatrix]?
                    let planimetry: SCNViewContainer = SCNViewContainer()
                    let planimetryRooms: SCNViewMapContainer = SCNViewMapContainer()
                    
                    if fileManager.fileExists(atPath: floorDataURL.path) {
                        let floorDataContents = try fileManager.contentsOfDirectory(at: floorDataURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        
                        for fileURL in floorDataContents {
                            if fileURL.pathExtension == "scn" || fileURL.pathExtension == "dae" {
                                if fileURL.lastPathComponent.contains("sceneObjects") {
                                    let objectScene = try SCNScene(url: fileURL, options: nil)
                                    sceneObjects.append(contentsOf: objectScene.rootNode.childNodes)
                                } else if fileURL.lastPathComponent.contains("scene") {
                                    scene = try SCNScene(url: fileURL, options: nil)
                                } else if fileURL.lastPathComponent.contains("sceneConfiguration") {
                                    sceneConfiguration = try SCNScene(url: fileURL, options: nil)
                                }
                            }
                            
                        }
                    }
                    
//                    if FileManager.default.fileExists(atPath: floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floorURL.lastPathComponent).usdz").path){
//                        planimetry.loadFloorPlanimetry(borders: true, usdzURL: floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floorURL.lastPathComponent).usdz"))
//                    }
//                    
                    let associationMatrixURL = floorURL.appendingPathComponent("\(floorURL.lastPathComponent).json")
                    if fileManager.fileExists(atPath: associationMatrixURL.path) {
                        if let loadedMatrix = loadRoomPositionFromJson(from: associationMatrixURL) {
                            associationMatrix = loadedMatrix
                            print("Matrix loaded for floor \(floorURL.lastPathComponent): \(String(describing: associationMatrix))\n")
                        } else {
                            print("Failed to load RotoTraslationMatrix from JSON file for floor \(floorURL.lastPathComponent)")
                        }
                    }
                    
                    let rooms = try loadRooms(from: floorURL)
                    
                    var floorRooms: [Room] = []
                    rooms.forEach { room in
                        floorRooms.append(room)
                    }
                    
                    let floor = Floor(_name: floorURL.lastPathComponent,
                                      _lastUpdate: lastModifiedDate,
                                      _planimetry: planimetry,
                                      _planimetryRooms: planimetryRooms,
                                      _associationMatrix: associationMatrix ?? [:],
                                      _rooms: rooms,
                                      _sceneObjects: sceneObjects,
                                      _scene: scene,
                                      _sceneConfiguration: sceneConfiguration,
                                      _floorURL: floorURL)
                    
                    if FileManager.default.fileExists(atPath: floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floorURL.lastPathComponent).usdz").path){
                        
                        planimetry.loadFloorPlanimetry(borders: true, floor: floor)
                        
                        floor.scene = planimetry.scnView.scene
                        
                        floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
                            if let nodeName = n.name {
                                return nodeName != "Room" &&
                                       nodeName != "Geom" &&
                                       !nodeName.hasSuffix("_grp") &&
                                       !nodeName.hasPrefix("unidentified")
                            }
                            return false
                        })
                        
                        if let sceneObjects = floor.sceneObjects {
                            print("Printing all valid nodes for \(floor.name):")
                                for node in sceneObjects {
                                    print("Node name: \(node.name ?? "Unnamed")")
                                }
                            } else {
                                print("No valid nodes found.")
                            }
                        
                    }else{
                        print("File .usdz for \(floor.name) planimetry is not available.")
                    }
                    
                    planimetryRooms.handler.loadRoomsMaps(
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
    
    private func loadRooms(from floorURL: URL) throws -> [Room] {
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
                    let sceneObjects: [SCNNode] = []
                    let planimetry: SCNViewContainer = SCNViewContainer()

                    let referenceMarkerURL = roomURL.appendingPathComponent("ReferenceMarker")
                    if fileManager.fileExists(atPath: referenceMarkerURL.path) {
                        let referenceMarkerContents = try fileManager.contentsOfDirectory(at: referenceMarkerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                        for fileURL in referenceMarkerContents {
                            // Load each ReferenceMarker file (assumed to be JSON files)
                            if fileURL.pathExtension == "json" {
                                let jsonData = try Data(contentsOf: fileURL)
                                let decodedMarkers = try JSONDecoder().decode([ReferenceMarker].self, from: jsonData)
                                referenceMarkers.append(contentsOf: decodedMarkers)
                            } else if fileURL.pathExtension == "jpg" || fileURL.pathExtension == "png" || fileURL.pathExtension == "JPG" || fileURL.pathExtension == "PNG" || fileURL.pathExtension == "JPEG" || fileURL.pathExtension == "jpeg" {
                                // Assuming the image file name is the same as the marker name
                                let imageName = fileURL.deletingPathExtension().lastPathComponent
                                let imagePath = fileURL
                                // Create a new ReferenceMarker
                                let coordinates = Coordinates(x: Float(Double.random(in: -100...100)), y: Float(Double.random(in: -100...100))) // Adjust accordingly
                                let rmUML = URL(fileURLWithPath: "") // Adjust accordingly
                                let newMarker = ReferenceMarker(_imagePath: imagePath, _imageName: imageName, _coordinates: coordinates, _rmUML: rmUML)
                                referenceMarkers.append(newMarker)
                            }
                        }
                    }
                    
                    let room = Room(_name: roomURL.lastPathComponent,
                                    _lastUpdate: lastModifiedDate,
                                    _planimetry: planimetry,
                                    _referenceMarkers: referenceMarkers,
                                    _transitionZones: transitionZones,
                                    _sceneObjects: sceneObjects,
                                    _roomURL: roomURL
                    )
                    
                    if FileManager.default.fileExists(atPath: roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path){
                        planimetry.loadRoomPlanimetry(room: room, borders: true)
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
            print("Folder created at: \(buildingURL.path)")
        } catch {
            print("Error creating folder for building \(building.name): \(error)")
        }
    }
    
    @MainActor func renameBuilding(building: Building, newName: String) throws -> Bool {
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
        
        return true
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
