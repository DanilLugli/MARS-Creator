//
//  Building.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//

import Foundation

class Building: Codable, ObservableObject {
    private var _id: UUID
    private var _name: String
    private var _lastUpdate: Date
    private var _floors: [Floor]
    private var _buildingURL: URL
    
    init(id: UUID, name: String, lastUpdate: Date, floors: [Floor], buildingURL: URL) {
        self._id = id
        self._name = name
        self._lastUpdate = lastUpdate
        self._floors = floors
        self._buildingURL = buildingURL
    }
    
    var id: UUID {
        get {
            return _id
        }
        // Il setter non è necessario poiché `id` è read-only
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
        // Il setter non è necessario poiché `lastUpdate` è read-only
    }
    
    var floors: [Floor] {
        get {
            return _floors
        }
        // Il setter non è necessario poiché `floors` è read-only
    }
    
    var buildingURL: URL {
        get {
            return _buildingURL
        }
    }
    
    static func fromJson(json: String) -> Building {
        // Implement JSON deserialization logic
        // Placeholder implementation, replace with actual logic
        return Building(id: UUID(), name: "", lastUpdate: Date(), floors: [], buildingURL: URL(string: "https://example.com")!)
    }
    
    func addFloor(floor: Floor) {
        // Implement logic to add floor
        _floors.append(floor)
    }
    
    func deleteFloorByName(name: String) {
        // Implement logic to delete floor by name
        _floors.removeAll { $0.name == name }
    }
    
    func createARLFile(fileURL: URL) {
        // Implement logic to create ARL file
    }
}
