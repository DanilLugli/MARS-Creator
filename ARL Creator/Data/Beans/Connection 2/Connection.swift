import Foundation

class Connection: Codable{
    private var _id = UUID()
    private var _name: String
    
    init(name: String) {
        self._name = name
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
}
