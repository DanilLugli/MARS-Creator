//
//  Building.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//

import Foundation

class Building: Encodable, ObservableObject {
    private var _id = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    @Published private var _floors: [Floor]
    private var _buildingURL: URL
    
    init(name: String, lastUpdate: Date, floors: [Floor], buildingURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._floors = floors
        self._buildingURL = buildingURL
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
    
    var floors: [Floor] {
        get {
            return _floors
        }
    }
    
    var buildingURL: URL {
        get {
            return _buildingURL
        }
    }
    
    // Implementazione personalizzata di Encodable
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case floors
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_floors, forKey: .floors)
    }
    
    func addFloor(floor: Floor) {
        _floors.append(floor)
    }
    
    func deleteFloorByName(name: String) {
        _floors.removeAll { $0.name == name }
    }
    
    func createARLFile(fileURL: URL) {
        // TODO: Implement logic to create ARL file
    }
}
