import Foundation
import ARKit
import SceneKit
import SwiftUI

class Room: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {
    private var _id: UUID = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    @Published private var _planimetry: SCNViewContainer?
    @Published private var _referenceMarkers: [ReferenceMarker]
    @Published private var _transitionZones: [TransitionZone]
    @Published private var _scene: SCNScene?
    @Published private var _sceneObjects: [SCNNode]?
    private var _roomURL: URL
    @Published private var _color: UIColor
    
    weak var parentFloor: Floor?
    
    init(_id: UUID = UUID(), _name: String, _lastUpdate: Date, _planimetry: SCNViewContainer? = nil, _referenceMarkers: [ReferenceMarker], _transitionZones: [TransitionZone], _scene: SCNScene? = SCNScene(), _sceneObjects: [SCNNode]? = nil, _roomURL: URL, parentFloor: Floor? = nil) {
        self._name = _name
        self._lastUpdate = _lastUpdate
        self._planimetry = _planimetry
        self._referenceMarkers = _referenceMarkers
        self._transitionZones = _transitionZones
        self._scene = _scene ?? SCNScene()
        self._sceneObjects = _sceneObjects
        self._roomURL = _roomURL
        self._color = Room.randomColor().withAlphaComponent(0.3)
        self.parentFloor = parentFloor
    }
    
    static func ==(lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
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
        }set{
            _referenceMarkers = newValue
        }
    }
    
    var transitionZones: [TransitionZone] {
        get {
            return _transitionZones
        }
        set{
            _transitionZones = newValue
        }
    }
    
    var scene: SCNScene? {
        get{
            return _scene
        }
        set{
            _scene = newValue
        }
    }
    
    var sceneObjects: [SCNNode]? {
        get {
            return _sceneObjects
        }
        set{
            _sceneObjects = newValue
        }
    }
    
    var roomURL: URL {
        get {
            return _roomURL
        }set{
            _roomURL = newValue
        }
    }
    
    var planimetry: SCNViewContainer {
        return _planimetry ?? SCNViewContainer()
    }
    
    var url: URL {
        get {
            return roomURL
        }
    }
    
    func getFloor(of room: Room) -> Floor? {
        return room.parentFloor
    }
    
    var color: UIColor{
        get{
            return _color
        }
        set{
            _color = newValue
        }
    }
    
    func hasConnections() -> Bool {
        return _transitionZones.contains { $0.connection != nil }
    }
    
    static func randomColor() -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 1.0),    // #FF5800
            UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),    // #FFD700
            UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0),    // #FF4500
            UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0),    // #00BFFF
            UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0),  // #228B22
            UIColor(red: 0.42, green: 0.35, blue: 0.8, alpha: 1.0),   // #6A5ACD
            UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0),   // #FF69B4
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0),  // #8B4513
            UIColor(red: 0.87, green: 0.63, blue: 0.87, alpha: 1.0),  // #DDA0DD
            UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1.0)   // #4682B4
        ]
        
        return colors[Int(arc4random_uniform(UInt32(colors.count)))]
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
    
    func toJSON() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    func addReferenceMarker(referenceMarker: ReferenceMarker) {
        _referenceMarkers.append(referenceMarker)
    }
    
    func addTransitionZone(transitionZone: TransitionZone){
        _transitionZones.append(transitionZone)
    }
    
    func deleteTransitionZone(transitionZone: TransitionZone) {
        _transitionZones.removeAll { $0.id == transitionZone.id }
    }
    
    func debugPrintRoom() {
        print("Room Debug Info:")
        print("-----------------------------")
        print("ID: \(_id)")
        print("Name: \(_name)")
        print("Last Update: \(_lastUpdate)")
        print("Room URL: \(_roomURL.path)")
        print("Reference Markers (\(_referenceMarkers.count)):")
        
        for marker in referenceMarkers {
            print("\tMarker ID: \(marker.id), Coordinates: \(marker.coordinates)")
        }
        
        print("Transition Zones (\(self.transitionZones.count)):")
        for zone in transitionZones {
            print("\tTransition Zone Name: \(zone.name)")
        }
        
        print("Scene Objects (\(String(describing: self.sceneObjects?.count))):")
        for object in sceneObjects! {
            print("\tObject Name: \(object.name ?? "Unnamed Object")")
        }
        
        print("-----------------------------\n")
    }
    
    
    func addConnection(from fromTransitionZone: TransitionZone, to targetRoom: Room, targetTransitionZone: TransitionZone) {

        let connectionFrom = AdjacentFloorsConnection(
            name: "Connection to \(targetRoom.name)",
            fromTransitionZone: fromTransitionZone.name,
            targetFloor: targetRoom.getFloor(of: targetRoom)?.name ?? "Error ParentFloor",
            targetRoom: targetRoom.name,
            targetTransitionZone: targetTransitionZone.name
        )
        
        let connectionTo = AdjacentFloorsConnection(
            name: "Connection to \(self.name)",
            fromTransitionZone: targetTransitionZone.name,
            targetFloor: self.roomURL.lastPathComponent,
            targetRoom: self.name,
            targetTransitionZone: fromTransitionZone.name
        )
        
        fromTransitionZone.connection?.append(connectionFrom)
        targetTransitionZone.connection?.append(connectionTo)
        
        if let index = _transitionZones.firstIndex(where: { $0.id == fromTransitionZone.id }) {
            _transitionZones[index].connection?.append(connectionFrom)
        }
        
        if let targetIndex = targetRoom._transitionZones.firstIndex(where: { $0.id == targetTransitionZone.id }) {
            targetRoom._transitionZones[targetIndex].connection?.append(connectionTo)
        }
        

        print("Connection added from \(fromTransitionZone.name) in room \(self.name) to \(targetTransitionZone.name) in room \(targetRoom.name).")
        print("Connection from \(fromTransitionZone.name) to \(targetTransitionZone.name): \(connectionFrom.name)")
        print("Connection from \(targetTransitionZone.name) to \(fromTransitionZone.name): \(connectionTo.name)")
    }
    
    func saveConnectionToJSON(for transitionZoneName: String, connection: AdjacentFloorsConnection, to url: URL) throws {
        //
    }

    
    func debugConnectionPrint() {
            print("Room: \(self.name)")
            print("Transition Zones and their Connections:")

            for transitionZone in self.transitionZones {
                print("Transition Zone: \(transitionZone.name)")
                
                if let connections = transitionZone.connection, !connections.isEmpty {
                    for (index, connection) in connections.enumerated() {
                        print("\tConnection \(index + 1): \(connection.name)")
                        
                        if let adjacentConnection = connection as? AdjacentFloorsConnection {
                            print("\t\tTarget Room: \(adjacentConnection.targetRoom)")
                            print("\t\tTarget Floor: \(adjacentConnection.targetFloor)")
                        }
                    }
                } else {
                    print("\tNo connections found.")
                }
            }
        }
}
