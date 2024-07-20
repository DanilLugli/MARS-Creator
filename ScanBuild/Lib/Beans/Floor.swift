import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: Encodable, Identifiable{
    
    private var _id = UUID()
    private var _name: String
    private var _lastUpdate: Date
    private var _planimetry: Image
    private var _associationMatrix: [String : RotoTraslationMatrix]
    private var _rooms: [Room]
    private var _sceneObjects: [SCNNode]?
    private var _scene: SCNScene?
    private var _sceneConfiguration: SCNScene?
    private var _floorURL: URL
    
    init(name: String, lastUpdate: Date, planimetry: Image, associationMatrix: [String : RotoTraslationMatrix], rooms: [Room], sceneObjects: [SCNNode]?, scene: SCNScene?, sceneConfiguration: SCNScene?, floorURL: URL) {
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
    
    var associationMatrix: [String : RotoTraslationMatrix] {
        return _associationMatrix
    }
    
    var rooms: [Room] {
        return Array(_rooms)
    }
    
    var sceneObjects: [SCNNode]? {
        return Array(_sceneObjects ?? [])
    }
    
    var scene: SCNScene? {
        return _scene
    }
    
    var sceneConfiguration: SCNScene? {
        return _sceneConfiguration
    }
    
    var floorURL: URL {
        return _floorURL
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
    }
    
    func deleteRoom(room: Room) {
        _rooms.removeAll { $0.id == room.id }
    }
    
    private func loadAssociationMatrix() -> [RotoTraslationMatrix] {
        // Implement logic to load association matrix
        return []
    }
    
    func saveAssociationMatrix(associationMatrix: [RotoTraslationMatrix]) -> Bool {
        // Implement logic to save association matrix
        return true
    }
    
    func createAssociationMatrix(room: Room, nodes: [(SCNNode, SCNNode)]) -> [RotoTraslationMatrix] {
        // Implement logic to create association matrix
        return []
    }
    
}
