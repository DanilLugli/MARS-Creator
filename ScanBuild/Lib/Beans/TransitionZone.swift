import Foundation
import SwiftUI

class TransitionZone: Codable, Identifiable {
    private var _id: UUID = UUID()
    private var _name: String
    private var _connection: Connection?
    private var _transitionArea: Coordinates
    private var _tzJsonURL: URL
    
    init(name: String, connection: Connection?, transitionArea: Coordinates, tzJsonURL: URL) {
        self._name = name
        self._connection = connection
        self._transitionArea = transitionArea
        self._tzJsonURL = tzJsonURL
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
    
    var connection: Connection? {
        get {
            return _connection
        }
    }
    
    var transitionArea: Coordinates {
        get {
            return _transitionArea
        }
    }

    var tzJsonURL: URL {
        get {
            return _tzJsonURL
        }
    }
    
    // Implementazione personalizzata di Codable
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case connection
        case transitionArea
        case tzJsonURL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(_name, forKey: .name)
        try container.encode(_connection, forKey: .connection)
        try container.encode(_transitionArea, forKey: .transitionArea)
        try container.encode(_tzJsonURL, forKey: .tzJsonURL)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        _name = try container.decode(String.self, forKey: .name)
        _connection = try container.decodeIfPresent(Connection.self, forKey: .connection)
        _transitionArea = try container.decode(Coordinates.self, forKey: .transitionArea)
        _tzJsonURL = try container.decode(URL.self, forKey: .tzJsonURL)
    }
    
    func overlapWith(rectangle: Rectangle) {
        // Implement logic to check if overlapping with another rectangle
    }
}
