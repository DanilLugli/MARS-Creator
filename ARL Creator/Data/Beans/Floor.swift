import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: NamedURL, Encodable, Identifiable, ObservableObject, Equatable, Hashable {

    private var _id = UUID()
    @Published private var _name: String

    @Published private var _rooms: [Room]
    @Published private var _scene: SCNScene? = nil
    @Published private var _sceneObjects: [SCNNode]? = nil
    
    @Published private var _planimetry: SCNViewContainer?
    @Published private var _planimetryRooms: SCNViewMapContainer?
    @Published var _associationMatrix: [String: RotoTraslationMatrix]
    
    @Published var isPlanimetryLoaded: Bool = false
    @Published var altitude: Float = 0
    var initialFloor: Bool {
        get {
                return UserDefaults.standard.bool(forKey: "initialFloor_\(name)")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "initialFloor_\(name)")
                objectWillChange.send() // Notifica SwiftUI del cambiamento
            }
        }
    
    private var _floorURL: URL
    
    private var _lastUpdate: Date

    init(_id: UUID = UUID(), _name: String, _lastUpdate: Date, _planimetry: SCNViewContainer? = nil, _planimetryRooms: SCNViewMapContainer? = nil, _associationMatrix: [String : RotoTraslationMatrix], _rooms: [Room], _sceneObjects: [SCNNode]? = nil, _scene: SCNScene? = nil, _floorURL: URL) {
        self._name = _name
        self._lastUpdate = _lastUpdate
        self._planimetry = _planimetry
        self._planimetryRooms = _planimetryRooms
        self._associationMatrix = _associationMatrix
        self._rooms = _rooms
        self._sceneObjects = _sceneObjects
        self._scene = _scene
        self._floorURL = _floorURL
    }
    
    static func ==(lhs: Floor, rhs: Floor) -> Bool {
        return lhs.id == rhs.id 
    }
    
    var id: UUID {
        return _id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
            objectWillChange.send() // Forza la notifica di cambiamento
            
        }
    }
    
    var lastUpdate: Date {
        return _lastUpdate
    }
    
    var planimetry: SCNViewContainer {
        get{
            return _planimetry ?? SCNViewContainer()
        }set{
            _planimetry = newValue
        }
    }
    
    var planimetryRooms: SCNViewMapContainer {
        get{
            return _planimetryRooms ?? SCNViewMapContainer()
        }set{
            _planimetryRooms = newValue
        }
    }
    
    var associationMatrix: [String: RotoTraslationMatrix] {
        get{
            return _associationMatrix
        }set{
            _associationMatrix = newValue
        }
    }
    
    var rooms: [Room] {
        get {
            return _rooms
        }
        set {
            _rooms = newValue
        }
    }
    
    func getRoom(_ room: Room) -> Room? {
        return rooms.first { $0.id == room.id}
    }
    
    var sceneObjects: [SCNNode]? {
        get{
            return _sceneObjects
        }
        set{
            _sceneObjects = newValue
        }
    }
    
    var scene: SCNScene? {
        get{
            return _scene
        }
        set{
            _scene = newValue
        }
    }
    
    var floorURL: URL {
        get {
            return _floorURL
        }
        set {
            _floorURL = newValue
        }
    }
    
    var url: URL {
        get {
            return floorURL
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case rooms
        case associationMatrix
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_rooms, forKey: .rooms)
        try container.encode(_associationMatrix, forKey: .associationMatrix)
    }
    
    func getRoomByName(_ name: String) -> Room? {
        return rooms.first { $0.name == name }
    }
    
    func addRoom(room: Room) {
        
        room.parentFloor = self
        _rooms.append(room)
        
        let roomsDirectory = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        let roomURL = roomsDirectory.appendingPathComponent(room.name)
        
        do {
            try FileManager.default.createDirectory(at: roomURL, withIntermediateDirectories: true, attributes: nil)
            room.roomURL = roomURL
            
            let subdirectories = ["JsonMaps", "JsonParametric", "Maps", "MapUsdz", "PlistMetadata", "ReferenceMarker", "TransitionZone"]
            
            for subdirectory in subdirectories {
                let subdirectoryURL = roomURL.appendingPathComponent(subdirectory)
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
        } catch {
            print("Error creating folder for room \(room.name): \(error)")
        }
    }
    
    func deleteRoom(room: Room) {
        
        // 1. Rimuove la stanza dalla memoria
        _rooms.removeAll { $0.id == room.id }
        
        // 2. Costruisce il percorso della cartella della stanza da eliminare
        let roomURL = floorURL
            .appendingPathComponent("Rooms")         // Directory "Rooms"
            .appendingPathComponent(room.name)      // Sottocartella con nome stanza
        
        do {
            // 3. Controlla se la cartella esiste e la elimina
            if FileManager.default.fileExists(atPath: roomURL.path) {
                try FileManager.default.removeItem(at: roomURL) // Elimina la cartella
                print("Cartella \(room.name) eliminata con successo.")
            } else {
                print("La cartella della stanza \(room.name) non esiste in \(roomURL.path).")
            }
        } catch {
            // 4. Gestisce eventuali errori
            print("Errore durante l'eliminazione della stanza \(room.name): \(error)")
        }
    }
   
    @MainActor func processRooms(for floor: Floor) {
        for room in floor.rooms {
            let roomScene = room.scene
            
            if let roomNode = roomScene?.rootNode.childNode(withName: "Floor0", recursively: true) {
                let originalScale = roomNode.scale
                let roomName = room.name
                
                roomNode.simdWorldPosition = simd_float3(0, 0, 0)
                roomNode.scale = originalScale
                
                if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
                    applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
                } else {
                    print("No RotoTraslationMatrix found for room: \(roomName)")
                }
                
                roomNode.name = roomName
                let material = SCNMaterial()
                material.diffuse.contents = floor.getRoomByName(roomName)?.color
                roomNode.geometry?.materials = [material]
                
                floor.scene?.rootNode.addChildNode(roomNode)
            } else {
                print("Node 'Floor0' not found in scene: \(String(describing: roomScene))")
            }
        }
        

        /// Applica una rototraslazione a un nodo SCNNode.
        /// - Parameters:
        ///   - node: Il nodo da trasformare.
        ///   - rotoTraslation: La matrice di rototraslazione contenente traslazione e rotazione.
        ///   - baseTransform: (Opzionale) Una matrice di trasformazione base. Default: utilizza la trasformazione attuale del nodo.
        @MainActor
        func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
            let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
            node.simdWorldTransform = combinedMatrix * node.simdWorldTransform
        }
    }

        
    @MainActor func renameRoom(floor: Floor, room: Room, newName: String) throws {
        let fileManager = FileManager.default
        let oldRoomURL = room.roomURL
        let oldRoomName = room.name
        let newRoomURL = oldRoomURL.deletingLastPathComponent().appendingPathComponent(newName)
        
        // Verifica se esiste già una stanza con il nuovo nome
        guard !fileManager.fileExists(atPath: newRoomURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già una stanza con il nome \(newName)"])
        }
        
        // Rinomina la cartella della stanza
        do {
            try fileManager.moveItem(at: oldRoomURL, to: newRoomURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella della stanza: \(error.localizedDescription)"])
        }
        
        // Aggiorna l'oggetto room
        room.roomURL = newRoomURL
        room.name = newName
        
        // Aggiorna i file nelle sottocartelle della room rinominata
        do {
            try renameRoomFilesInDirectories(room: room, newRoomName: newName)
        } catch {
            print("Errore durante la rinomina dei file nelle sottocartelle della stanza: \(error.localizedDescription)")
        }
        
        // Aggiorna il contenuto del file JSON nella cartella del floor associato
        do {
            try updateRoomInFloorJSON(floor: floor, oldRoomName: oldRoomName, newRoomName: newName)
        } catch {
            print("Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.objectWillChange.send() // Notifica SwiftUI del cambiamento
        }
    }
    
    func updateRoomInFloorJSON(floor: Floor, oldRoomName: String, newRoomName: String) throws {
        _ = FileManager.default
        
        let jsonFileURL = floor.floorURL.appendingPathComponent("\(floor.name).json")
        
        do {
            let jsonData = try Data(contentsOf: jsonFileURL)
            var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            
            guard let roomData = jsonDict?[oldRoomName] as? [String: Any] else {
                throw NSError(domain: "com.example.ScanBuild", code: 8, userInfo: [NSLocalizedDescriptionKey: "Il nome della stanza \(oldRoomName) non esiste nel file JSON del floor."])
            }
            
            jsonDict?.removeValue(forKey: oldRoomName)
            jsonDict?[newRoomName] = roomData
            
            
            let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict as Any, options: .prettyPrinted)
            try updatedJsonData.write(to: jsonFileURL)
            
            
            if let oldMatrix = floor._associationMatrix[oldRoomName] {
                floor._associationMatrix.removeValue(forKey: oldRoomName)
                floor._associationMatrix[newRoomName] = oldMatrix
            } else {
                print("Nessuna matrice trovata per la stanza \(oldRoomName) nella _associationMatrix.")
            }
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 9, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)"])
        }
    }
    
    func renameRoomFilesInDirectories(room: Room, newRoomName: String) throws {
        let fileManager = FileManager.default
        let directories = ["PlistMetadata", "MapUsdz", "JsonParametric", "Maps", "JsonMaps"]
        
        let roomDirectoryURL = room.roomURL
        
        // Ottieni il vecchio nome della stanza
        let oldRoomName = room.name
        
        for directory in directories {
            let directoryURL = roomDirectoryURL.appendingPathComponent(directory)
            // Verifica se la directory esiste
            guard fileManager.fileExists(atPath: directoryURL.path)
            else {
                print("La directory \(directory) non esiste per la stanza \(room.name).")
                continue
            }
            
            // Ottieni tutti i file all'interno della directory
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            
            // Elimina i file con il vecchio nome
            for fileURL in fileURLs {
                let fileNameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
                if fileNameWithoutExtension == oldRoomName {
                    do {
                        try fileManager.removeItem(at: fileURL)
                    } catch {
                        throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'eliminazione del file \(fileURL.lastPathComponent) in \(directory): \(error.localizedDescription)"])
                    }
                }
            }
            
            // Ottieni la lista aggiornata dei file dopo l'eliminazione
            let updatedFileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            
            // Rinominare tutti i file rimanenti con il nuovo nome
            for oldFileURL in updatedFileURLs {
                let fileExtension = oldFileURL.pathExtension
                let newFileName = "\(newRoomName).\(fileExtension)"
                let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                
                // Se esiste già un file con il nuovo nome, eliminalo
                if fileManager.fileExists(atPath: newFileURL.path) {
                    do {
                        try fileManager.removeItem(at: newFileURL)
                        
                    } catch {
                        throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'eliminazione del file esistente \(newFileURL.lastPathComponent) in \(directory): \(error.localizedDescription)"])
                    }
                }
                
                do {
                    try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                    
                } catch {
                    throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file \(oldFileURL.lastPathComponent) in \(directory): \(error.localizedDescription)"])
                }
            }
        }
    }
    
    func loadAssociationMatrixFromJSON(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: [String: [[Double]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            for (key, value) in dictionary {
                guard let translationArray = value["translation"],
                      let r_YArray = value["R_Y"] else {
                    print("Error: Missing keys in dictionary")
                    continue
                }
                
                let translationMatrix = simd_float4x4(rows: translationArray.map { simd_float4($0.map { Float($0) }) })
                let r_YMatrix = simd_float4x4(rows: r_YArray.map { simd_float4($0.map { Float($0) }) })
                
                let rotoTranslationMatrix = RotoTraslationMatrix(name: key, translation: translationMatrix, r_Y: r_YMatrix)
                
                self._associationMatrix[key] = rotoTranslationMatrix
            }
            
        } catch {
            print("Error loading JSON data: \(error)")
        }
    }
    
    func saveAssociationMatrixToJSON(fileURL: URL) {
        do {
            // Crea un dizionario per contenere i dati da salvare in JSON
            var dictionary: [String: [String: [[Double]]]] = [:]
            
            // Itera su tutte le chiavi e valori nell'association matrix
            for (key, value) in _associationMatrix {
                // Converti la matrice translation in un array di array di Double
                let translationArray: [[Double]] = (0..<4).map { index in
                    [Double(value.translation[index, 0]), Double(value.translation[index, 1]), Double(value.translation[index, 2]), Double(value.translation[index, 3])]
                }
                
                // Converti la matrice r_Y in un array di array di Double
                let r_YArray: [[Double]] = (0..<4).map { index in
                    [Double(value.r_Y[index, 0]), Double(value.r_Y[index, 1]), Double(value.r_Y[index, 2]), Double(value.r_Y[index, 3])]
                }
                
                // Crea un dizionario per contenere le matrici per questa stanza
                dictionary[key] = [
                    "translation": translationArray,
                    "R_Y": r_YArray
                ]
            }
            
            // Converti il dizionario in JSON
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            
            // Scrivi i dati JSON nel file
            try jsonData.write(to: fileURL)
            
        } catch {
            print("Error saving association matrix to JSON: \(error)")
        }
    }
    
    func updateAssociationMatrixInJSON(for roomName: String, fileURL: URL) {
        do {
            // Leggi il contenuto del file JSON
            var jsonData = try Data(contentsOf: fileURL)
            guard var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: [[Double]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            // Assicurati che la chiave esista nel dizionario JSON
            guard let value = _associationMatrix[roomName] else {
                print("Room name \(roomName) not found in the association matrix")
                return
            }
            
            // Converti la matrice translation in un array di array di Double
            let translationArray = (0..<4).map { index in
                [Double(value.translation[0, index]), Double(value.translation[1, index]), Double(value.translation[2, index]), Double(value.translation[3, index])]
            }
            
            // Converti la matrice r_Y in un array di array di Double
            let r_YArray = (0..<4).map { index in
                [Double(value.r_Y[0, index]), Double(value.r_Y[1, index]), Double(value.r_Y[2, index]), Double(value.r_Y[3, index])]
            }
            
            // Aggiorna le matrici nel dizionario JSON per la chiave specificata
            jsonDict[roomName]?["translation"] = translationArray
            jsonDict[roomName]?["R_Y"] = r_YArray
            
            // Converti il dizionario aggiornato in JSON
            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            
            // Scrivi i dati JSON nel file
            try jsonData.write(to: fileURL)
            
        } catch {
            print("Error updating association matrix in JSON: \(error)")
        }
    }
    
    func isMatrixPresent(named matrixName: String, inFileAt url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let matricesDict = json as? [String: [String: [[Double]]]] else {
                print("Il formato del file JSON non è corretto.")
                return false
            }
            
            return matricesDict[matrixName] != nil
            
        } catch {
            print("Errore durante la lettura del file JSON: \(error)")
            return false
        }
    }
    
    
    
    private func simd_float4(_ array: [Float]) -> simd_float4 {
        return simd.simd_float4(array[0], array[1], array[2], array[3])
    }
    
    private func simd_float4x4(rows: [simd_float4]) -> simd_float4x4 {
        return simd.simd_float4x4(rows[0], rows[1], rows[2], rows[3])
    }
    
    func validateFloor() {
        // Verifica il nome del floor
        if _name.isEmpty {
            print("Error: Floor name is missing.")
        }
        
        // Verifica la data di ultimo aggiornamento
        if _lastUpdate.timeIntervalSince1970 == 0 {
            print("Error: Last update date is invalid or missing.")
        }
        
        // Verifica la planimetria
        if _planimetry == nil {
            print("Error: Planimetry is missing.")
        }
        
        // Verifica la planimetria delle stanze
        if _planimetryRooms == nil {
            print("Error: Planimetry rooms are missing.")
        }
        
        // Verifica l'URL del floor
        if _floorURL.path.isEmpty || !FileManager.default.fileExists(atPath: _floorURL.path) {
            print("Error: Floor URL is invalid or does not exist.")
        }
        
        // Verifica la matrice di associazione
        if _associationMatrix.isEmpty {
            print("Error: Association matrix is empty.")
        }
        
        // Verifica le stanze associate
        if _rooms.isEmpty {
            print("Error: No rooms are associated with the floor.")
        } else {
            // Controlla che ogni stanza abbia parametri validi
            for (index, room) in _rooms.enumerated() {
                if room.name.isEmpty {
                    print("Error: Room \(index + 1) is missing a name.")
                }
                if room.roomURL.path.isEmpty || !FileManager.default.fileExists(atPath: room.roomURL.path) {
                    print("Error: Room \(index + 1) URL is invalid or does not exist.")
                }
            }
        }
        
        // Verifica gli oggetti della scena
        if _sceneObjects == nil {
            print("Error: Scene objects are missing.")
        }
        
        // Verifica la scena
        if _scene == nil {
            print("Error: Scene is missing.")
        }
    }
}
