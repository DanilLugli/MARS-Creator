import Foundation

struct Connection: Codable, Hashable {
    var labels: [TransitionZone] = []
    private var matrix: [Bool] = []
    private var size: Int = 0
    
    mutating func addZoneToConnection(zone: TransitionZone) {
        guard !labels.contains(zone) else { return }
        
        labels.append(zone)
        size += 1
        
        let newSize = (size * (size + 1)) / 2
        matrix += [Bool](repeating: false, count: newSize - matrix.count)
    }
    
    mutating func createConnection(zone1: TransitionZone, zone2: TransitionZone) {
        guard let index1 = getIndexMatrix(zone: zone1),
              let index2 = getIndexMatrix(zone: zone2) else { return }
        
        let index = getMatrixIndex(row: index1, col: index2)
        matrix[index] = true
    }
    
    mutating func deleteConnection(zone1: TransitionZone, zone2: TransitionZone) {
        guard let index1 = getIndexMatrix(zone: zone1),
              let index2 = getIndexMatrix(zone: zone2) else { return }
        
        let index = getMatrixIndex(row: index1, col: index2)
        matrix[index] = false
    }
    
    func getConnection(zone1: TransitionZone, zone2: TransitionZone) -> Bool {
        guard let index1 = getIndexMatrix(zone: zone1),
              let index2 = getIndexMatrix(zone: zone2) else { return false }
        
        let index = getMatrixIndex(row: index1, col: index2)
        return matrix[index]
    }
    
    private func getIndexMatrix(zone: TransitionZone) -> Int? {
        return labels.firstIndex(of: zone)
    }
    
    private func getMatrixIndex(row: Int, col: Int) -> Int {
        let (small, large) = row < col ? (row, col) : (col, row)
        return (large * (large + 1)) / 2 + small
    }
    
    func getConnectedZones(zone: TransitionZone) -> [TransitionZone] {
        guard let index = getIndexMatrix(zone: zone) else { return [] }
        
        var connectedZones: [TransitionZone] = []
        
        for i in 0..<labels.count {
            if i != index && getConnection(zone1: labels[index], zone2: labels[i]) {
                connectedZones.append(labels[i])
            }
        }
        
        return connectedZones
    }
    
    func listConnections() -> [FloorBridge] {
        var connections: [FloorBridge] = []
        
        for i in 0..<labels.count {
            for j in i+1..<labels.count {
                if getConnection(zone1: labels[i], zone2: labels[j]) {
                    connections.append(FloorBridge(from: labels[i].name, to: labels[j].name))
                }
            }
        }
        
        return connections
    }
}

struct FloorBridge: Identifiable, CustomStringConvertible {
    var description: String { "Connection \(from) - \(to)" }
    
    var id = UUID()
    var from: String
    var to: String
    
    init(id: UUID = UUID(), from: String, to: String) {
        self.id = id
        self.from = from
        self.to = to
    }
}
