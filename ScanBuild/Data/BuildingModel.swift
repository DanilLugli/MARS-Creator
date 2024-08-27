import Foundation
import ARKit
import SceneKit
import SwiftUI

class BuildingModel: ObservableObject {
    //TODO: Fare Dump
    //TODO: Creare percorsi relativi
    //TODO: Creare fromARFile
    
    private static var _instance: BuildingModel?
    private static let LOGGER = Logger(tag: String(describing: BuildingModel.self))
    
    static var SCANBUILD_ROOT: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("ScanBuild")
    }
    static let FLOOR_DATA_FOLDER = "Data"
    static let FLOOR_ROOMS_FOLDER = "Rooms"
    static let ASSASSOCIATION_MATRIX_FILE = ""
    
    
    @Published var buildings: [Building]
    
    private init() {
        self.buildings = []
        do {
            try self.loadBuildingsFromRoot()
        } catch {
            BuildingModel.LOGGER.log("Errore durante il caricamento dei buildings: \(error)")
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
        
        //Aggiungi 10 building
        for i in 1...3 {
            let building = Building(name: "Building \(i)", lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: ""))
            
            // Aggiungi 5 piani al primo edificio
            for j in 1...5 {
                let floor = Floor(name: "Floor \(j)", lastUpdate: Date(), planimetry: Image(""), associationMatrix: [String : RotoTraslationMatrix](), rooms: [], sceneObjects: nil, scene: nil, sceneConfiguration: nil, floorURL: URL(fileURLWithPath: ""))
                
                
                for k in 1...5 {
                    //Aggiungi 5 Room al primo piano
                    let room = Room(name: "Room \(k)", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                    
                    //Aggiungi 2 TransitionZone alla Room
                    for z in 1...2 {
                        let xMin = Float.random(in: 0...10)
                        let yMin = Float.random(in: 0...10)
                        let transitionZone = TransitionZone(name: "Scala \(z)", connection: nil, transitionArea: Coordinates(x: xMin, y: yMin))
                        do {
                            try room.addTransitionZone(transitionZone: transitionZone)
                        } catch {
                            print("Errore durante l'aggiunta della TransitionZone \(transitionZone.name): \(error)")
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
    
    func loadBuildingsFromRoot() throws {
        let fileManager = FileManager.default
        
        // Verifica se la cartella root esiste
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
    
    private func loadFloors(from buildingURL: URL) throws -> [Floor] {
        let fileManager = FileManager.default
        let floorURLs = try fileManager.contentsOfDirectory(at: buildingURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        
        var floors: [Floor] = []
        for floorURL in floorURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: floorURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let attributes = try fileManager.attributesOfItem(atPath: floorURL.path)
                if let lastModifiedDate = attributes[.modificationDate] as? Date {
                    
                    let floorDataURL = floorURL//.appendingPathComponent(BuildingModel.FLOOR_DATA_FOLDER)
                    
                    var sceneObjects: [SCNNode] = []
                    var scene: SCNScene? = nil
                    var sceneConfiguration: SCNScene? = nil
                    var associationMatrix: [String : RotoTraslationMatrix]?
                    
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
                    
                    // Carica l'associationMatrix dal file JSON se esiste
                    let associationMatrixURL = floorURL.appendingPathComponent("\(floorURL.lastPathComponent).json")
                    if fileManager.fileExists(atPath: associationMatrixURL.path) {
                        if let loadedMatrix = loadRoomPositionFromJson(from: associationMatrixURL) {
                            associationMatrix = loadedMatrix
                            print("Matrix loaded for floor \(floorURL.lastPathComponent): \(associationMatrix)")
                        } else {
                            print("Failed to load RotoTraslationMatrix from JSON file for floor \(floorURL.lastPathComponent)")
                        }
                    }
                    
                    let rooms = try loadRooms(from: floorURL)
                    
                    let floor = Floor(name: floorURL.lastPathComponent,
                                      lastUpdate: lastModifiedDate,
                                      planimetry: Image(""),
                                      associationMatrix: associationMatrix ?? [:],
                                      rooms: rooms,
                                      sceneObjects: sceneObjects,
                                      scene: scene,
                                      sceneConfiguration: sceneConfiguration,
                                      floorURL: floorURL)
                    
//                    let associationMatrixURL = floorURL.appendingPathComponent("\(floor.name).json")
//                    if fileManager.fileExists(atPath: associationMatrixURL.path) {
//                        floor.loadAssociationMatrixFromJSON(fileURL: associationMatrixURL)
//                        print("Matrix: \(floor.associationMatrix)")
//                    }
                    
                    floors.append(floor)
                }
            }
        }
        return floors
    }
    
    private func loadRooms(from floorURL: URL) throws -> [Room] {
        let fileManager = FileManager.default
        
        // Modifica il percorso per puntare alla directory "<floor_name>_Rooms"
        let roomsDirectoryURL = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        
        // Ottieni l'elenco delle directory delle stanze
        let roomURLs = try fileManager.contentsOfDirectory(at: roomsDirectoryURL, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles)
        
        var rooms: [Room] = []
        for roomURL in roomURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: roomURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let attributes = try fileManager.attributesOfItem(atPath: roomURL.path)
                if let lastModifiedDate = attributes[.modificationDate] as? Date {
                    
                    var referenceMarkers: [ReferenceMarker] = []
                    var transitionZones: [TransitionZone] = []
                    var sceneObjects: [SCNNode] = []
                    var scene: SCNScene? = nil
                    var worldMap: ARWorldMap? = nil
                    
                    // Load ReferenceMarker data
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
                    
                    
                    let transitionZone = TransitionZone(
                        name: "Scale",
                        connection: nil,
                        transitionArea: Coordinates(x: Float(Double.random(in: -90...90)), y: Float(Double.random(in: -180...180)))
                    )
                    transitionZones.append(transitionZone)
                        
                        // Salva la TransitionZone casuale come file JSON
//                        let jsonData = try JSONEncoder().encode(transitionZone)
//                        try jsonData.write(to: roomURL.appendingPathComponent("TransitionZone"))
                    
                    
                    // Load TransitionZone data
//                    let transitionZoneURL = roomURL.appendingPathComponent("TransitionZone")
//                    if fileManager.fileExists(atPath: transitionZoneURL.path) {
//                        let transitionZoneContents = try fileManager.contentsOfDirectory(at: transitionZoneURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//                        for fileURL in transitionZoneContents {
////                            if fileURL.pathExtension == "json" {
////                                let jsonData = try Data(contentsOf: fileURL)
////                                let decodedZones = try JSONDecoder().decode([TransitionZone].self, from: jsonData)
////                                transitionZones.append(contentsOf: decodedZones)
////                            }
////                            else {
//
//                          //  }
//                        }
//                    }

//                    let transitionZoneURL = roomURL.appendingPathComponent("TransitionZone/TransitionZone.json")
//                    if fileManager.fileExists(atPath: transitionZoneURL.path) {
//                        let jsonData = try Data(contentsOf: transitionZoneURL)
//                        let decodedZones = try JSONDecoder().decode([TransitionZone].self, from: jsonData)
//                        transitionZones.append(contentsOf: decodedZones)
//                    }
                    
                    //                    // Load sceneObjects and scene from MapUsdz
                    //                    let mapUsdzURL = roomURL.appendingPathComponent("MapUsdz")
                    //                    if fileManager.fileExists(atPath: mapUsdzURL.path) {
                    //                        let mapUsdzContents = try fileManager.contentsOfDirectory(at: mapUsdzURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    //                        for fileURL in mapUsdzContents {
                    //                            if fileURL.pathExtension == "usdz" {
                    //                                scene = try SCNScene(url: fileURL, options: nil)
                    //                                sceneObjects.append(contentsOf: scene!.rootNode.childNodes)
                    //                            }
                    //                        }
                    //                    }
                    
                    let room = Room(name: roomURL.lastPathComponent, lastUpdate: lastModifiedDate, referenceMarkers: referenceMarkers, transitionZones: transitionZones, sceneObjects: sceneObjects, scene: scene, worldMap: worldMap, roomURL: roomURL)
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
    
    func renameBuilding(building: Building, newName: String) throws -> Bool {
        let fileManager = FileManager.default
        let oldBuildingURL = building.buildingURL
        let newBuildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(newName)

        // Verifica se esiste già un building con il nuovo nome
        guard !fileManager.fileExists(atPath: newBuildingURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già un building con il nome \(newName)"])
        }

        // Rinomina la cartella del building
        do {
            try fileManager.moveItem(at: oldBuildingURL, to: newBuildingURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella del building: \(error.localizedDescription)"])
        }
        
        // Aggiorna l'oggetto building
        building.buildingURL = newBuildingURL
        building.name = newName
        
        self.buildings = []
        
        do {
            try self.loadBuildingsFromRoot()
        } catch {
            BuildingModel.LOGGER.log("Errore durante il caricamento dei buildings: \(error)")
        }

        // Log the rename
        BuildingModel.LOGGER.log("Building rinominato da \(building.name) a \(newName)")
        
        return true
    }
    
    func deleteBuilding(building: Building) {
        // Rimuovi il building dall'array
        buildings.removeAll { $0.id == building.id }
        
        // Ottieni il percorso del building
        let buildingURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent(building.name)
        
        // Elimina la cartella del building
        do {
            try FileManager.default.removeItem(at: buildingURL)
            print("Folder deleted at: \(buildingURL.path)")
        } catch {
            print("Error deleting folder for building \(building.name): \(error.localizedDescription)")
        }
    }
}
