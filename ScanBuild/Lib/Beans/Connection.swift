import Foundation

struct Connection: Codable, Hashable {
    var labels: [Room] = []
    private var matrix: [Bool] = []
    private var size: Int = 0
    
    mutating func addRoomToConnection(room: Room) {
        guard !labels.contains(room) else { return }
        
        labels.append(room)
        size += 1
        
        let newSize = (size * (size + 1)) / 2
        matrix += [Bool](repeating: false, count: newSize - matrix.count)
    }
    
    mutating func createConnection(room1: Room, room2: Room) {
        guard let index1 = getIndexMatrix(room: room1),
              let index2 = getIndexMatrix(room: room2) else { return }
        
        let index = getMatrixIndex(row: index1, col: index2)
        matrix[index] = true
    }
    
    mutating func deleteConnection(room1: Room, room2: Room) {
        guard let index1 = getIndexMatrix(room: room1),
              let index2 = getIndexMatrix(room: room2) else { return }
        
        let index = getMatrixIndex(row: index1, col: index2)
        matrix[index] = false
    }
    
    func getConnection(room1: Room, room2: Room) -> Bool {
        guard let index1 = getIndexMatrix(room: room1),
              let index2 = getIndexMatrix(room: room2) else { return false }
        
        let index = getMatrixIndex(row: index1, col: index2)
        return matrix[index]
    }
    
    private func getIndexMatrix(room: Room) -> Int? {
        return labels.firstIndex(of: room)
    }
    
    private func getMatrixIndex(row: Int, col: Int) -> Int {
        let (small, large) = row < col ? (row, col) : (col, row)
        return (large * (large + 1)) / 2 + small
    }
    
    func getConnectedRooms(room: Room) -> [Room] {
        guard let index = getIndexMatrix(room: room) else { return [] }
        
        var connectedRooms: [Room] = []
        
        for i in 0..<labels.count {
            if i != index && getConnection(room1: labels[index], room2: labels[i]) {
                connectedRooms.append(labels[i])
            }
        }
        
        return connectedRooms
    }
    
    func listConnections() -> [FloorBridge] {
        var connections: [FloorBridge] = []
        
        for i in 0..<labels.count {
            for j in i+1..<labels.count {
                if getConnection(room1: labels[i], room2: labels[j]) {
                    connections.append(FloorBridge(from: labels[i].floorName, to: labels[j].floorName))
                }
            }
        }
        
        return connections
    }
    
    
}

struct FloorBridge: Identifiable, CustomStringConvertible{
    var description: String{"Connection \(from) - \(to)"}
    
    var id = UUID()
    var from: String
    var to: String
    
    
}
