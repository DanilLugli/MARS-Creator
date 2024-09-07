import Foundation
import SceneKit
import SwiftUI

class TransitionZone: Codable, Identifiable, Equatable, ObservableObject {
    @Published private var _id: UUID = UUID()
    @Published private var _name: String
    @Published private var _connection: Connection?
    

    init(name: String, connection: Connection?) {
        self._name = name
        self._connection = connection
    }
    
    static func ==(lhs: TransitionZone, rhs: TransitionZone) -> Bool {
        return lhs.id == rhs.id // Compara gli ID, o qualsiasi altra proprietà unica
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
        }set{
            _connection = newValue
        }
    }
    
    // Implementazione personalizzata di Codable
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case connection
        case tzJsonURL
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(_name, forKey: .name)
        try container.encode(_connection, forKey: .connection)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        _name = try container.decode(String.self, forKey: .name)
        _connection = try container.decodeIfPresent(Connection.self, forKey: .connection)
    }
}
