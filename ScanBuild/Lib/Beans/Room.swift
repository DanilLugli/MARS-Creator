import Foundation
import ARKit
import SceneKit

class Room: Encodable {
    private var _id: UUID = UUID()
    private var _name: String
    private var _lastUpdate: Date
    private var _referenceMarkers: [ReferenceMarker]
    private var _transitionZones: [TransitionZone]
    private var _sceneObjects: [SCNNode]
    private var _scene: SCNScene?
    private var _worldMap: ARWorldMap?
    private var _roomURL: URL
    
    init(name: String, lastUpdate: Date, referenceMarkers: [ReferenceMarker], transitionZones: [TransitionZone], sceneObjects: [SCNNode], scene: SCNScene?, worldMap: ARWorldMap?, roomURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._referenceMarkers = referenceMarkers
        self._transitionZones = transitionZones
        self._sceneObjects = sceneObjects
        self._scene = scene
        self._worldMap = worldMap
        self._roomURL = roomURL
    }
    
    var id: UUID {
        get {
            return _id
        }
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
        get {
            return _lastUpdate
        }
    }
    
    var referenceMarkers: [ReferenceMarker] {
        get {
            return _referenceMarkers
        }
    }
    
    var transitionZones: [TransitionZone] {
        get {
            return _transitionZones
        }
    }
    
    var sceneObjects: [SCNNode] {
        get {
            return _sceneObjects
        }
    }
    
    var scene: SCNScene? {
        get {
            return _scene
        }
    }
    
    var worldMap: ARWorldMap? {
        get {
            return _worldMap
        }
    }
    
    var roomURL: URL {
        get {
            return _roomURL
        }
    }
    
    // Implementazione personalizzata di Encodable
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case referenceMarkersCount
        case transitionZonesCount
        case transitionZones
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_referenceMarkers.count, forKey: .referenceMarkersCount)
        try container.encode(_transitionZones.count, forKey: .transitionZonesCount)
        try container.encode(_transitionZones, forKey: .transitionZones)
    }
    
    // JSON Serialization using Encodable
    func toJSON() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    func addReferenceMarker(referenceMarker: ReferenceMarker) {
        _referenceMarkers.append(referenceMarker)
    }

    func addTransitionZone(transitionZone: TransitionZone) throws {
        _transitionZones.append(transitionZone)
    }
    
    func deleteTransitionZone(transitionZone: TransitionZone) {
        _transitionZones.removeAll { $0.id == transitionZone.id }
    }
}
