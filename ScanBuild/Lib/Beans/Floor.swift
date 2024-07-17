//
//  Floor.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//
import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: Codable {
    
    private var _id: UUID
    private var _name: String
    private var _lastUpdate: Date
    private var _planimetry: Image
    private var _associationMatrix: [RotoTraslationMatrix]
    private var _rooms: [Room]
    private var _sceneObjects: [SCNNode]?
    private var _scene: SCNScene?
    private var _sceneConfiguration: SCNScene?
    private var _floorURL: URL
    
    init(id: UUID, name: String, lastUpdate: Date, planimetry: Image, associationMatrix: [RotoTraslationMatrix], rooms: [Room], sceneObjects: [SCNNode]?, scene: SCNScene?, sceneConfiguration: SCNScene?, floorURL: URL) {
        self._id = id
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
    
    var associationMatrix: [RotoTraslationMatrix] {
        return _associationMatrix
    }
    
    var rooms: [Room] {
        return _rooms
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
        return _floorURL
    }
    
    // Implementazione personalizzata di Codable
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case roomsCount
        case associationMatrix
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_rooms.count, forKey: .roomsCount)
        try container.encode(_associationMatrix, forKey: .associationMatrix)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _name = try container.decode(String.self, forKey: .name)
        _lastUpdate = try container.decode(Date.self, forKey: .lastUpdate)
        let roomsCount = try container.decode(Int.self, forKey: .roomsCount)
        _associationMatrix = try container.decode([RotoTraslationMatrix].self, forKey: .associationMatrix)
        
        // Placeholder values for properties not included in the Codable conformance
        _id = UUID()
        _planimetry = Image("")
        _rooms = Array(repeating: Room(id: UUID(), name: "", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(string: "https://example.com")!), count: roomsCount)
        _sceneObjects = []
        _scene = nil
        _sceneConfiguration = nil
        _floorURL = URL(string: "https://example.com")!
    }
    
    // JSON Serialization using Codable
    func toJSON() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    static func fromJSON(_ jsonString: String) -> Floor? {
        if let jsonData = jsonString.data(using: .utf8) {
            return try? JSONDecoder().decode(Floor.self, from: jsonData)
        }
        return nil
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
    
    private func loadSceneObjects() {
        // Implement logic to load scene objects
    }
    
    private func loadSceneConfiguration() {
        // Implement logic to load scene configuration
    }
    
    private func loadScene() {
        // Implement logic to load scene
    }
    
    func toFile() {
        // Implement logic to save to file
    }
}


