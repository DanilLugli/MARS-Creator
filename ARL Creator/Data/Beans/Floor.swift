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
    @Published var _associationMatrix: [String: RoomPositionMatrix]
    @Published var isPlanimetryLoaded: Bool = false
    @Published var altitude: Float = 0
    var initialFloor: Bool {
        get {
                return UserDefaults.standard.bool(forKey: "initialFloor_\(name)")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "initialFloor_\(name)")
                objectWillChange.send()
            }
        }
    private var _floorURL: URL
    private var _lastUpdate: Date

    init(_id: UUID = UUID(), _name: String, _lastUpdate: Date, _planimetry: SCNViewContainer? = nil, _planimetryRooms: SCNViewMapContainer? = nil, _associationMatrix: [String : RoomPositionMatrix], _rooms: [Room], _sceneObjects: [SCNNode]? = nil, _scene: SCNScene? = nil, _floorURL: URL) {
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
    
    //MARK: - Equatable & Hashable
    static func ==(lhs: Floor, rhs: Floor) -> Bool {
        return lhs.id == rhs.id 
    }
    
    var id: UUID {
        return _id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    
    //MARK: - Getter & Setter
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
            objectWillChange.send()
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
    
    var associationMatrix: [String: RoomPositionMatrix] {
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
    
    //MARK: - Manage Room
    
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
        
//        self._associationMatrix[room.name] = RotoTraslationMatrix(name: room.name, translation: matrix_identity_float4x4, r_Y: matrix_identity_float4x4)
//        saveAssociationMatrixToJSON(fileURL: floorURL.appendingPathComponent("\(floorURL.lastPathComponent).json"))
        
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
    
    func deleteRoom(room: Room) {
       
        _rooms.removeAll { $0.id == room.id }
    
        let roomURL = floorURL
            .appendingPathComponent("Rooms")         // Directory "Rooms"
            .appendingPathComponent(room.name)      // Sottocartella con nome stanza
        
        self._associationMatrix.removeValue(forKey: room.name)
        
        
        do {

            if FileManager.default.fileExists(atPath: roomURL.path) {
                try FileManager.default.removeItem(at: roomURL) // Elimina la cartella
                print("Cartella \(room.name) eliminata con successo.")
                try deleteRoomFromFloorJSON(nameRoom: room.name)
            } else {
                print("La cartella della stanza \(room.name) non esiste in \(roomURL.path).")
            }
        } catch {
            print("Errore durante l'eliminazione della stanza \(room.name): \(error)")
        }
            
        self.planimetryRooms.handler.loadRoomsMaps(
            floor: self,
            rooms: self.rooms
        )
        
    }
    
    func getRoomByName(_ name: String) -> Room? {
        return rooms.first { $0.name == name }
    }
    
    func getRoom(_ room: Room) -> Room? {
        return rooms.first { $0.id == room.id}
    }
   
//    @MainActor func processRooms(for floor: Floor) {
//        for room in floor.rooms {
//            let roomScene = room.scene
//            
//            if let roomNode = roomScene?.rootNode.childNode(withName: "Floor0", recursively: true) {
//                let originalScale = roomNode.scale
//                let roomName = room.name
//                
//                roomNode.simdWorldPosition = simd_float3(0, 0, 0)
//                roomNode.scale = originalScale
//                
//                if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
//                    applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
//                } else {
//                    print("No RotoTraslationMatrix found for room: \(roomName)")
//                }
//                
//                roomNode.name = roomName
//                let material = SCNMaterial()
//                material.diffuse.contents = floor.getRoomByName(roomName)?.color
//                roomNode.geometry?.materials = [material]
//                
//                floor.scene?.rootNode.addChildNode(roomNode)
//            } else {
//                print("Node 'Floor0' not found in scene: \(String(describing: roomScene))")
//            }
//        }
//        
//
//        /// Applica una rototraslazione a un nodo SCNNode.
//        /// - Parameters:
//        ///   - node: Il nodo da trasformare.
//        ///   - rotoTraslation: La matrice di rototraslazione contenente traslazione e rotazione.
//        ///   - baseTransform: (Opzionale) Una matrice di trasformazione base. Default: utilizza la trasformazione attuale del nodo.
//        @MainActor
//        func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RoomPositionMatrix) {
//            let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
//            node.simdWorldTransform = combinedMatrix * node.simdWorldTransform
//        }
//    }

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
    
    func deleteRoomFromFloorJSON(nameRoom: String) throws {
        _ = FileManager.default
        let jsonFileURL = self.floorURL.appendingPathComponent("\(self.name).json")
        
        do {
            let jsonData = try Data(contentsOf: jsonFileURL)
            var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            
            // Controlla se la stanza esiste nel file JSON
            guard jsonDict?[nameRoom] != nil else {
                throw NSError(domain: "com.example.ScanBuild", code: 10, userInfo: [NSLocalizedDescriptionKey: "La stanza \(nameRoom) non esiste nel file JSON del floor."])
            }
            
            // Rimuove la stanza dal JSON
            jsonDict?.removeValue(forKey: nameRoom)
            
            // Scrive i dati aggiornati nel file
            let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict as Any, options: .prettyPrinted)
            try updatedJsonData.write(to: jsonFileURL)
            
            // Rimuove la stanza anche dall'associazione matrice
            if self._associationMatrix[nameRoom] != nil {
                self._associationMatrix.removeValue(forKey: nameRoom)
                print("Stanza \(nameRoom) rimossa dalla _associationMatrix.")
            } else {
                print("Nessuna matrice trovata per la stanza \(nameRoom) nella _associationMatrix.")
            }
            
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 11, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'eliminazione della stanza dal file JSON del floor: \(error.localizedDescription)"])
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
    
    func addIdentityMatrixToJSON(to directoryURL: URL, for floor: Floor, roomName: String) {
        let fileManager = FileManager.default
        var folderURL = directoryURL

        if folderURL.pathExtension.lowercased() == "json" {
            folderURL.deleteLastPathComponent()
        }

        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Errore creando la directory: \(error.localizedDescription)")
                return
            }
        }

        let fileURL = folderURL.appendingPathComponent("\(floor.name).json")

        var jsonDict: [String: [String: [[Double]]]] = [:]

        // ✅ Mantieni le chiavi esistenti nel JSON senza modificarle
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                if let existingDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: [[Double]]]] {
                    jsonDict = existingDict
                }
            } catch {
                print("Errore nella lettura del file JSON: \(error.localizedDescription)")
            }
        }

        // ✅ Definizione delle matrici identità 4x4
        let identityMatrix: [[Double]] = [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]
        ]

        // ✅ Aggiungi la nuova chiave senza modificare le altre
        jsonDict[roomName] = [
            "translation": identityMatrix,
            "R_Y": identityMatrix
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Matrice identità aggiunta per '\(roomName)' in \(fileURL.path)")
        } catch {
            print("Errore nel salvataggio del JSON: \(error.localizedDescription)")
        }
    }
    
    func isRoomPositionMatrixInJSON(fileURL: URL, roomName: String) -> Bool {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Il file JSON non esiste: \(fileURL.path)")
            return false
        }

        do {
            // Leggi i dati dal file JSON
            let data = try Data(contentsOf: fileURL)
            
            // Decodifica il JSON in un dizionario
            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: [[Double]]]] {
                // Controlla se la chiave esiste nel dizionario
                return jsonDict[roomName] != nil
            } else {
                print("Errore: Il formato del JSON non è valido.")
                return false
            }
        } catch {
            print("Errore nella lettura del file JSON: \(error.localizedDescription)")
            return false
        }
    }
    
//    func loadRoomPositionMatrixFromJSON(fileURL: URL) {
//        do {
//            let data = try Data(contentsOf: fileURL)
//            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
//            guard let dictionary = jsonObject as? [String: [String: [[Double]]]] else {
//                print("Error: Cannot convert JSON data to dictionary")
//                return
//            }
//            
//            for (key, value) in dictionary {
//                guard let translationArray = value["translation"],
//                      let r_YArray = value["R_Y"] else {
//                    print("Error: Missing keys in dictionary")
//                    continue
//                }
//                
//                let translationMatrix = simd_float4x4(rows: translationArray.map { simd_float4($0.map { Float($0) }) })
//                let r_YMatrix = simd_float4x4(rows: r_YArray.map { simd_float4($0.map { Float($0) }) })
//                
//                let rotoTranslationMatrix = RoomPositionMatrix(name: key, translation: translationMatrix, r_Y: r_YMatrix)
//                
//                self._associationMatrix[key] = rotoTranslationMatrix
//            }
//            
//        } catch {
//            print("Error loading JSON data: \(error)")
//        }
//    }
    
    func saveRoomPositionMatrixToJSON(fileURL: URL) {
        do {
           
            var dictionary: [String: [String: [[Double]]]] = [:]
            
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
            var jsonData = try Data(contentsOf: fileURL)
            guard var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: [[Double]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            guard let value = _associationMatrix[roomName] else {
                print("Room name \(roomName) not found in the association matrix")
                return
            }
            
            let translationArray = (0..<4).map { index in
                [Double(value.translation[0, index]), Double(value.translation[1, index]), Double(value.translation[2, index]), Double(value.translation[3, index])]
            }
            
            let r_YArray = (0..<4).map { index in
                [Double(value.r_Y[0, index]), Double(value.r_Y[1, index]), Double(value.r_Y[2, index]), Double(value.r_Y[3, index])]
            }
            
            jsonDict[roomName]?["translation"] = translationArray
            jsonDict[roomName]?["R_Y"] = r_YArray
            
            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            
            try jsonData.write(to: fileURL)
            
        } catch {
            print("Error updating association matrix in JSON: \(error)")
        }
    }
    
//    func updateRoomPositionMatrixInJSON(for roomName: String, fileURL: URL) {
//        do {
//            var jsonData = try Data(contentsOf: fileURL)
//            guard var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: [[Double]]]] else {
//                print("Error: Cannot convert JSON data to dictionary")
//                return
//            }
//
//            guard let value = _associationMatrix[roomName] else {
//                print("Room name \(roomName) not found in the association matrix")
//                return
//            }
//            
//            // ✅ Mantiene le matrici salvate per righe
//            let translationArray = (0..<4).map { row in
//                (0..<4).map { col in Double(value.translation[row, col]) }
//            }
//
//            let r_YArray = (0..<4).map { row in
//                (0..<4).map { col in Double(value.r_Y[row, col]) }
//            }
//            
//            jsonDict[roomName] = ["translation": translationArray, "R_Y": r_YArray]
//
//            jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
//            try jsonData.write(to: fileURL)
//
//        } catch {
//            print("Error updating association matrix in JSON: \(error)")
//        }
//    }
    
    func saveOrUpdateAssociationMatrix(to directoryURL: URL, for floor: Floor, associationMatrix: [String: RoomPositionMatrix]) {
        let fileManager = FileManager.default
        // Se il directoryURL ha estensione "json", usiamo il suo parent come directory
        var folderURL = directoryURL
        if folderURL.pathExtension.lowercased() == "json" {
            folderURL.deleteLastPathComponent()
        }
        
        // Assicuriamoci che la directory esista
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Errore creando la directory: \(error.localizedDescription)")
                return
            }
        }
        
        // Costruisci il percorso completo del file JSON, es. "First.json"
        let fileURL = folderURL.appendingPathComponent("\(floor.name).json")
        
        // Dizionario in cui inserire le entry, struttura: [roomName: ["translation": [[Double]], "R_Y": [[Double]]]]
        var jsonDict: [String: [String: [[Double]]]] = [:]
        
        // Se il file esiste, prova a leggerlo e convertirlo in un dizionario
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: [[Double]]]] {
                    jsonDict = dict
                } else {
                    print("Non riesco a convertire il JSON in un dizionario. Verrà creato un nuovo dizionario.")
                }
            } catch {
                print("Errore nella lettura del file JSON: \(error.localizedDescription)")
            }
        }
        
        // Aggiorna il dizionario con le entry provenienti da associationMatrix
        for (roomName, roomPositionMatrix) in associationMatrix {
            // Conversione della matrice translation in un array di array di Double
            let translationArray: [[Double]] = (0..<4).map { row in
                (0..<4).map { col in
                    Double(roomPositionMatrix.translation[row, col])
                }
            }
            
            // Conversione della matrice r_Y in un array di array di Double
            let r_YArray: [[Double]] = (0..<4).map { row in
                (0..<4).map { col in
                    Double(roomPositionMatrix.r_Y[row, col])
                }
            }
            
            // Inserisci o aggiorna la chiave relativa a roomName
            jsonDict[roomName] = [
                "translation": translationArray,
                "R_Y": r_YArray
            ]
        }
        
        // Serializza il dizionario aggiornato in JSON e scrivilo sul file
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Association matrix salvata/aggiornata correttamente in \(fileURL.path)")
        } catch {
            print("Errore nel salvataggio del JSON: \(error.localizedDescription)")
        }
    }
    
    
    public func createIdentityRotoTraslationMatrix(forRoom roomName: String) -> [String: Any] {
    
        let identityMatrix: [[Double]] = [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]
        ]
        
       
        let rotoTraslation: [String: Any] = [
            "translation": identityMatrix,
            "R_Y": identityMatrix
        ]
        
        return [roomName: rotoTraslation]
    }
    
    func isMatrixPresent(named matrixName: String, inFileAt url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let matricesDict = json as? [String: [String: [[Double]]]] else {
                return false
            }
            
            return matricesDict[matrixName] != nil
            
        } catch {
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
