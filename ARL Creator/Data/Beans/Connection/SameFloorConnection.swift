import Foundation

class SameFloorConnection: Connection {
    private var _targetRoom: String
    
    init(name: String, targetRoom: String) {
        self._targetRoom = targetRoom
        super.init(name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _targetRoom = try container.decode(String.self, forKey: .targetRoom)
        try super.init(from: decoder) 
    }
    
    var targetRoom: String {
        get {
            return _targetRoom
        }
        set {
            _targetRoom = newValue
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case targetRoom
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_targetRoom, forKey: .targetRoom)
        try super.encode(to: encoder)  // Codifica anche le proprietà della classe madre
    }
}


