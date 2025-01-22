import Foundation
import ARKit
import SceneKit
import SwiftUI

class Room: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {

    private var _id: UUID = UUID()
    @Published private var _name: String

    @Published private var _scene: SCNScene?
    @Published private var _sceneObjects: [SCNNode]?
    
    @Published private var _planimetry: SCNViewContainer?
    //@Published private var _roomPosition: SCNViewMapContainer?
    @Published private var _referenceMarkers: [ReferenceMarker]
    @Published private var _transitionZones: [TransitionZone]
    
    @Published private var _connections: [AdjacentFloorsConnection] = []
    
    private var _roomURL: URL
    @Published private var _color: UIColor
    private var _lastUpdate: Date
    
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
        // Carica il colore salvato o genera un nuovo colore casuale
        if let savedColor = Room.loadColor(for: _name) {
            self._color = savedColor
        } else {
            let randomColor = Room.randomColor().withAlphaComponent(0.3)
            self._color = randomColor
            Room.saveColor(randomColor, for: _name) // Salva il nuovo colore
        }
        
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
    
    var connections: [AdjacentFloorsConnection] {
        get {
            return _connections
        }
        set {
            _connections = newValue
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
    
    var color: UIColor {
        get {
            return _color
        }
        set {
            _color = newValue
            Room.saveColor(newValue, for: _name) // Salva il colore ogni volta che viene aggiornato
        }
    }
    
    // MARK: - Persistenza del colore
    private static func saveColor(_ color: UIColor, for roomName: String) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) else {
            print("Failed to encode color for room \(roomName)")
            return
        }
        
        UserDefaults.standard.set(data, forKey: "RoomColor_\(roomName)")
        print("Color saved for room \(roomName)")
    }
    
    private static func loadColor(for roomName: String) -> UIColor? {
        guard let data = UserDefaults.standard.data(forKey: "RoomColor_\(roomName)"),
              let color = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return nil
        }
        print("Color loaded for room \(roomName)")
        return color
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
            print("\tMarker ID: \(marker.id), Marker name: \(marker.imageName)")
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
    
    func addConnection(to targetRoom: Room, altitude: Float) {
        // Crea la connessione dalla stanza corrente alla stanza di destinazione
        let connectionFrom = AdjacentFloorsConnection(
            name: "Connection to \(targetRoom.name)",
            targetFloor: targetRoom.getFloor(of: targetRoom)?.name ?? "Error ParentFloor",
            targetRoom: targetRoom.name,
            altitude: altitude
        )
        
        // Crea la connessione inversa dalla stanza di destinazione alla stanza corrente
        let connectionTo = AdjacentFloorsConnection(
            name: "Connection to \(self.name)",
            targetFloor: self.roomURL.lastPathComponent,
            targetRoom: self.name,
            altitude: -altitude // L'altitudine inversa rispetto alla connessione iniziale
        )
        
        // Aggiungi la connessione alla stanza corrente
        self.connections.append(connectionFrom)
        
        // Aggiungi la connessione inversa alla stanza di destinazione
        targetRoom.connections.append(connectionTo)
        
        print("Connection added from room \(self.name) to room \(targetRoom.name) with altitude \(altitude).")
        print("Reverse connection added from room \(targetRoom.name) to room \(self.name) with altitude \(-altitude).")
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
    
    func validateRoom() {
        print("Validating Room: \(self.name)")
        
        // Verifica il nome
        if _name.isEmpty {
            print("Error: Room name is missing.")
        }
        
        // Verifica la data di ultimo aggiornamento
        if _lastUpdate.timeIntervalSince1970 == 0 {
            print("Error: Last update date is invalid or missing.")
        }
        
        // Verifica la planimetria
        if _planimetry == nil {
            print("Error: Planimetry is missing.")
        }
        
        // Verifica i marker di riferimento
        if _referenceMarkers.isEmpty {
            print("Error: No reference markers are defined.")
        }
        
        // Verifica le zone di transizione
        if _transitionZones.isEmpty {
            print("Error: No transition zones are defined.")
        }
        
        // Verifica la scena
        if _scene == nil {
            print("Error: Scene is missing.")
        }
        
        // Verifica gli oggetti della scena
        if _sceneObjects == nil || _sceneObjects?.isEmpty == true {
            print("Error: Scene objects are missing.")
        }
        
        // Verifica l'URL della stanza
        if _roomURL.path.isEmpty || !FileManager.default.fileExists(atPath: _roomURL.path) {
            print("Error: Room URL is invalid or does not exist.")
        }
        
        // Verifica il colore
        if _color == .clear {
            print("Error: Room color is invalid.")
        }
        
        // Verifica il piano padre (opzionale, ma utile per debugging)
        if parentFloor == nil {
            print("Warning: Room does not have an associated parent floor.")
        }
        
        print("Validation complete for Room: \(self.name)")
    }
}
