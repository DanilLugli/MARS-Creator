import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: NamedURL, Encodable, Identifiable, ObservableObject {
    
    private var _id = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    private var _planimetry: Image
    @Published private var _associationMatrix: [String: RotoTraslationMatrix]
    @Published private var _rooms: [Room]
    @Published private var _sceneObjects: [SCNNode]?
    @Published private var _scene: SCNScene?
    @Published private var _sceneConfiguration: SCNScene?
    private var _floorURL: URL
    
    init(name: String, lastUpdate: Date, planimetry: Image, associationMatrix: [String: RotoTraslationMatrix], rooms: [Room], sceneObjects: [SCNNode]?, scene: SCNScene?, sceneConfiguration: SCNScene?, floorURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._planimetry = planimetry
        self._associationMatrix = associationMatrix
        self._rooms = rooms
        self._sceneObjects = sceneObjects
        self._scene = scene
        self._sceneConfiguration = sceneConfiguration
        self._floorURL = floorURL
    }
    
    var id: UUID {
        return _id
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var lastUpdate: Date {
        return _lastUpdate
    }
    
    var planimetry: Image {
        return _planimetry
    }
    
    var associationMatrix: [String: RotoTraslationMatrix] {
        get{
            return _associationMatrix
        }set{
            _associationMatrix = newValue
        }
    }
    
    var rooms: [Room] {
        get {
            return _rooms
        }
        set {
            _rooms = newValue
        }
    }
    
    var sceneObjects: [SCNNode]? {
        return _sceneObjects
    }
    
    var scene: SCNScene? {
        return _scene
    }
    
    var sceneConfiguration: SCNScene? {
        return _sceneConfiguration
    }
    
    var floorURL: URL {
        get {
            return _floorURL
        }
        set {
            _floorURL = newValue
        }
    }
    
    var url: URL {
        get {
            return floorURL
        }
    }
    
    // Implementazione personalizzata di Encodable
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case rooms
        case associationMatrix
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_rooms, forKey: .rooms)
        try container.encode(_associationMatrix, forKey: .associationMatrix)
    }
    
    func addRoom(room: Room) {
        _rooms.append(room)
        
        // Creare la directory della stanza all'interno di "<floor_name>_Rooms"
        let roomsDirectory = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        let roomURL = roomsDirectory.appendingPathComponent(room.name)
        
        do {
            try FileManager.default.createDirectory(at: roomURL, withIntermediateDirectories: true, attributes: nil)
            room.roomURL = roomURL
            print("Folder created at: \(roomURL.path)")
            
            // Creare le cartelle all'interno della directory della stanza
            let subdirectories = ["JsonMaps", "JsonParametric", "Maps", "MapUsdz", "PlistMetadata", "ReferenceMarker", "TransitionZone"]
            
            for subdirectory in subdirectories {
                let subdirectoryURL = roomURL.appendingPathComponent(subdirectory)
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created at: \(subdirectoryURL.path)")
            }
            
        } catch {
            print("Error creating folder for room \(room.name): \(error)")
        }
    }

    func deleteRoom(room: Room) {
        _rooms.removeAll { $0.id == room.id }
        
        let roomURL = floorURL.appendingPathComponent(room.name)
        do {
            try FileManager.default.removeItem(at: roomURL)
            print("Folder deleted at: \(roomURL.path)")
        } catch {
            print("Error deleting folder for room \(room.name): \(error)")
        }
    }
    
    func loadAssociationMatrixFromJSON(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonDecoder = JSONDecoder()
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: [String: [[Float]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            for (key, value) in dictionary {
                guard let translationArray = value["translation"],
                      let r_YArray = value["R_Y"] else {
                    print("Error: Missing keys in dictionary")
                    continue
                }
                
                let translationMatrix = simd_float4x4(rows: translationArray.map { simd_float4($0) })
                let r_YMatrix = simd_float4x4(rows: r_YArray.map { simd_float4($0) })
                
                let rotoTranslationMatrix = RotoTraslationMatrix(name: key, translation: translationMatrix, r_Y: r_YMatrix)
                
                self._associationMatrix[key] = rotoTranslationMatrix
            }
        } catch {
            print("Error loading JSON data: \(error)")
        }
    }
    
    func isMatrixPresent(named matrixName: String, inFileAt url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let matricesDict = json as? [String: [String: [[Double]]]] else {
                print("Il formato del file JSON non è corretto.")
                return false
            }
            
            return matricesDict[matrixName] != nil
            
        } catch {
            print("Errore durante la lettura del file JSON: \(error)")
            return false
        }
    }
    
    // ... Altre funzioni
    
    private func simd_float4(_ array: [Float]) -> simd_float4 {
        return simd.simd_float4(array[0], array[1], array[2], array[3])
    }
    
    private func simd_float4x4(rows: [simd_float4]) -> simd_float4x4 {
        return simd_float4x4(rows: rows)
    }
    
//    private func loadAssociationMatrix() -> [RotoTraslationMatrix] {
//        // Implement logic to load association matrix
//        return []
//    }
    
    func saveAssociationMatrix(associationMatrix: [RotoTraslationMatrix]) -> Bool {
        // Implement logic to save association matrix
        return true
    }
    
//    func createAssociationMatrix(room: Room, nodes: [(SCNNode, SCNNode)]) -> [RotoTraslationMatrix] {
//        // Implement logic to create association matrix
//        return []
//    }
}
