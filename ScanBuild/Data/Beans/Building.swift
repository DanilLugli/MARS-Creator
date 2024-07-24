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
        set{
            _buildingURL = newValue
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
        
        let floorURL = buildingURL.appendingPathComponent(floor.name)
        do {
            try FileManager.default.createDirectory(at: floorURL, withIntermediateDirectories: true, attributes: nil)
            floor.floorURL = floorURL
            print("Folder created at: \(floorURL.path)")
            
            // Creare le cartelle aggiuntive all'interno della directory del piano
            let dataDirectory = floorURL.appendingPathComponent("\(floor.name)_Data")
            let roomsDirectory = floorURL.appendingPathComponent("\(floor.name)_Rooms")
            
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: roomsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            print("Data directory created at: \(dataDirectory.path)")
            print("Rooms directory created at: \(roomsDirectory.path)")
            
        } catch {
            print("Error creating folder for floor \(floor.name): \(error)")
        }
    }

    func deleteFloorByName(name: String) {
        _floors.removeAll { $0.name == name }
        
        let floorURL = buildingURL.appendingPathComponent(name)
        do {
            try FileManager.default.removeItem(at: floorURL)
            print("Folder deleted at: \(floorURL.path)")
        } catch {
            print("Error deleting folder for floor \(name): \(error)")
        }
    }
    
    func createARLFile(fileURL: URL) {
        // TODO: Implement logic to create ARL file
    }
}
