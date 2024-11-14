//
//  Building.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//

import Foundation
import SwiftUICore

class Building: Encodable, ObservableObject, Hashable {
    private var _id = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    @Published private var _floors: [Floor]
    @Published private var _buildingURL: URL
    
    init(name: String, lastUpdate: Date, floors: [Floor], buildingURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._floors = floors
        self._buildingURL = buildingURL
    }
    
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
    
    static func == (lhs: Building, rhs: Building) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    
    func getFloor(_ floor: Floor) -> Floor? {
        return floors.first { $0.id == floor.id }
    }
    
    func addFloor(floor: Floor) {
        _floors.append(floor)
        
        let floorURL = buildingURL.appendingPathComponent(floor.name)
        do {
            try FileManager.default.createDirectory(at: floorURL, withIntermediateDirectories: true, attributes: nil)
            floor.floorURL = floorURL
            print("Folder created at: \(floorURL.path)")
            
            // Creare le cartelle aggiuntive all'interno della directory del piano
            let dataDirectory = floorURL//.appendingPathComponent(BuildingModel.FLOOR_DATA_FOLDER)
            let roomsDirectory = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
            
            try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: roomsDirectory, withIntermediateDirectories: true, attributes: nil)
            
            print("Data directory created at: \(dataDirectory.path)")
            print("Rooms directory created at: \(roomsDirectory.path)")
            
            // Creare le cartelle aggiuntive all'interno della directory Data
            let jsonParametricDirectory = dataDirectory.appendingPathComponent("JsonParametric")
            print("PINO \(jsonParametricDirectory)")
            let mapUsdzDirectory = dataDirectory.appendingPathComponent("MapUsdz")
            let plistMetadataDirectory = dataDirectory.appendingPathComponent("PlistMetadata")
            
            try FileManager.default.createDirectory(at: jsonParametricDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: mapUsdzDirectory, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(at: plistMetadataDirectory, withIntermediateDirectories: true, attributes: nil)
            
            print("JsonParametric directory created at: \(jsonParametricDirectory.path)")
            print("MapUsdz directory created at: \(mapUsdzDirectory.path)")
            print("PlistMetadata directory created at: \(plistMetadataDirectory.path)")
            
           
            
        } catch {
            print("Error creating folder for floor \(floor.name): \(error)")
        }
    }
    
    func deleteFloor(floor: Floor) {
        // Rimuovi il floor dall'array _floors
        _floors.removeAll { $0.id == floor.id }
        
        // Ottieni l'URL della cartella del floor da eliminare
        let floorURL = buildingURL.appendingPathComponent(floor.name)
        
        // Elimina la cartella del floor dal file system
        do {
            if FileManager.default.fileExists(atPath: floorURL.path) {
                try FileManager.default.removeItem(at: floorURL)
                print("Floor \(floor.name) eliminato con successo da \(floorURL.path).")
            } else {
                print("La cartella del floor \(floor.name) non esiste.")
            }
        } catch {
            print("Errore durante l'eliminazione del floor \(floor.name): \(error)")
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
    
    @MainActor func renameFloor(floor: Floor, newName: String) throws -> Bool {

        floor.name = newName
        
        let fileManager = FileManager.default
        let oldFloorURL = floor.floorURL
        let newFloorURL = oldFloorURL.deletingLastPathComponent().appendingPathComponent(newName)

        guard !fileManager.fileExists(atPath: newFloorURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già un floor con il nome \(newName)"])
        }

        do {
            try fileManager.moveItem(at: oldFloorURL, to: newFloorURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella del floor: \(error.localizedDescription)"])
        }
       
        floor.floorURL = newFloorURL
        
        for room in floor.rooms {
            print("OLD: \(room.roomURL) ")
            room.roomURL = floor.floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER).appendingPathComponent("\(room.name)")
            print("NEW: \(room.roomURL) ")
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }

        do {
            try renameFilesInFloorDirectoriesAndJSON(floor: floor, newName: newName)
        } catch {
            print("Errore durante la rinomina dei file: \(error.localizedDescription)")
        }
        
        BuildingModel.getInstance().buildings = []

        do {
            try BuildingModel.getInstance().loadBuildingsFromRoot()
        } catch {
            print("Errore durante il caricamento dei buildings: \(error)")
        }

        return true
    }
    
    func renameFilesInFloorDirectoriesAndJSON(floor: Floor, newName: String) throws {
        let fileManager = FileManager.default
        let directories = ["PlistMetadata", "MapUsdz", "JsonParametric"]
        
        // Rinomina tutti i file .json nella cartella principale del floor
        let floorDirectoryURL = floor.floorURL
        let floorFiles = try fileManager.contentsOfDirectory(at: floorDirectoryURL, includingPropertiesForKeys: nil)
        
        for oldFileURL in floorFiles where oldFileURL.pathExtension == "json" {
            let oldFileName = oldFileURL.lastPathComponent
            let newFileName = "\(newName).json"
            let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            
            do {
                try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                print("File .json rinominato da \(oldFileName) a \(newFileName) nella cartella principale del floor.")
            } catch {
                throw NSError(domain: "com.example.ScanBuild", code: 7, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file .json \(oldFileName): \(error.localizedDescription)"])
            }
        }

        // Itera su ciascuna delle cartelle (PlistMetadata, MapUsdz, JsonParametric)
        for directory in directories {
            let directoryURL = floorDirectoryURL.appendingPathComponent(directory)
            
            // Verifica se la directory esiste
            guard fileManager.fileExists(atPath: directoryURL.path) else {
                print("La directory \(directory) non esiste per il floor \(floor.name).")
                continue
            }

            // Ottieni tutti i file all'interno della directory
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

            // Itera su ciascun file per rinominarlo
            for oldFileURL in fileURLs {
                let oldFileName = oldFileURL.lastPathComponent
                let fileExtension = oldFileURL.pathExtension
                let newFileName = "\(newName).\(fileExtension)"
                let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                
                do {
                    try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                    print("File rinominato da \(oldFileName) a \(newFileName) nella directory \(directory).")
                } catch {
                    throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file \(oldFileName) in \(directory): \(error.localizedDescription)"])
                }
            }
        }
    }
    
    func createARLFile(fileURL: URL) {
        // TODO: Implement logic to create ARL file
    }
}
