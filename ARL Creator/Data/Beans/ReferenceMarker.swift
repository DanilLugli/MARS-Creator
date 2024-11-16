//
//  ReferenceMarker.swift
//  ScanBuild
//
//  Created by Danil Lugli on 10/07/24.
//
//
//  ReferenceMarker.swift
//  ScanBuild
//
//  Created by Danil Lugli on 10/07/24.
//

import Foundation
import SwiftUI
import ARKit

class ReferenceMarker: ObservableObject, Codable, Identifiable {
    
    private var _id: UUID = UUID()
    @Published private var _image: Image? = nil
    @Published private var _imageName: String
    @Published private var _physicalWidth: CGFloat
    private var _imagePath: URL
    private var _coordinates: Coordinates
    private var _rmUML: URL
    
    // Nome del file JSON per salvare i dati del marker
    private let jsonFileName = "MarkerData.json"
    
    init(_imagePath: URL, _imageName: String, _coordinates: Coordinates, _rmUML: URL, _physicalWidth: CGFloat) {
        self._imagePath = _imagePath
        self._imageName = _imageName
        self._coordinates = _coordinates
        self._rmUML = _rmUML
        self._physicalWidth = _physicalWidth
    }
    
    var id: UUID {
        return _id
    }
    
    var image: Image {
        if _image == nil {
            if let imageData = try? Data(contentsOf: _imagePath),
               let uiImage = UIImage(data: imageData) {
                _image = Image(uiImage: uiImage)
            } else {
                _image = Image(systemName: "photo")
            }
        }
        return _image!
    }
    
    var imageName: String {
        get { return _imageName }
        set {
            _imageName = newValue
        }
    }
    
    var physicalWidth: CGFloat {
        get { return _physicalWidth }
        set {
            _physicalWidth = newValue
        }
    }
    
    // MARK: - JSON Persistence Methods
    
    /// Carica i dati del marker da un file JSON, se esistente
    private func loadMarkerData(from fileURL: URL) {
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File JSON non esiste, verrà creato alla prima modifica.")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let markersData = try decoder.decode([String: MarkerData].self, from: data)
            
            // Carica i dati del marker attuale
            if let markerData = markersData[_imageName] {
                _imageName = markerData.name
                _physicalWidth = markerData.width
            }
        } catch {
            print("Errore nella lettura del file JSON: \(error)")
        }
    }
    
    /// Salva o aggiorna i dati del marker nel file JSON
    public func saveMarkerData(to fileURL: URL, old oldName: String, new newName: String, size newWidth: CGFloat) {
        let referenceMarkerURL = fileURL.deletingLastPathComponent()
        var markersData: [String: MarkerData] = [:]
        let fileManager = FileManager.default
        
        // Cerca il file con il vecchio nome, indipendentemente dall'estensione
        if let fileWithExtension = try? fileManager.contentsOfDirectory(at: referenceMarkerURL, includingPropertiesForKeys: nil)
            .first(where: { $0.deletingPathExtension().lastPathComponent == oldName }) {

            // Costruisce il nuovo URL con il nuovo nome e l'estensione esistente
            let newFileURL = fileWithExtension.deletingLastPathComponent().appendingPathComponent(newName).appendingPathExtension(fileWithExtension.pathExtension)
            
            do {
                try fileManager.moveItem(at: fileWithExtension, to: newFileURL)
                print("File rinominato da \(fileWithExtension.lastPathComponent) a \(newFileURL.lastPathComponent)")
            } catch {
                print("Errore nel rinominare il file: \(error)")
            }
        } else {
            print("File con il nome \(oldName) non trovato.")
        }
        
        // Carica i dati dal file JSON, se esiste
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                markersData = try decoder.decode([String: MarkerData].self, from: data)
            } catch {
                print("Errore nella lettura del file JSON esistente: \(error)")
            }
        }
        
        // Controlla se esiste un record per oldName e aggiorna i dati
        if let markerData = markersData[oldName] {
            markersData.removeValue(forKey: oldName) // Rimuove il vecchio record
            markersData[newName] = MarkerData(name: newName, width: markerData.width) // Aggiunge con il nuovo nome
            print("Dati aggiornati per \(newName) nel JSON.")
        } else {
            // Aggiunge direttamente i nuovi dati se oldName non esiste
            markersData[newName] = MarkerData(name: newName, width: newWidth)
            print("Dati aggiunti per \(newName) nel JSON poiché \(oldName) non era presente.")
        }
        
        // Salva i dati aggiornati nel file JSON
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(markersData)
            try data.write(to: fileURL)
            print("Dati salvati correttamente nel file JSON.")
        } catch {
            print("Errore nel salvataggio del file JSON: \(error)")
        }
    }
    
    struct MarkerData: Codable {
        var name: String
        var width: CGFloat
    }
    
    func asARReferenceImage() -> ARReferenceImage? {
        if let imageData = try? Data(contentsOf: _imagePath),
           let uiImage = UIImage(data: imageData),
           let cgImage = uiImage.cgImage {
            let referenceImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: _physicalWidth)
            referenceImage.name = _imageName
            return referenceImage
        }
        return nil
    }
    
    // Implementazione di `Codable`
    private enum CodingKeys: String, CodingKey {
        case id, imageName, coordinates, rmUML, imagePath, physicalWidth
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(_imageName, forKey: .imageName)
        try container.encode(_coordinates, forKey: .coordinates)
        try container.encode(_rmUML, forKey: .rmUML)
        try container.encode(_imagePath, forKey: .imagePath)
        try container.encode(_physicalWidth, forKey: .physicalWidth)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        _imageName = try container.decode(String.self, forKey: .imageName)
        _coordinates = try container.decode(Coordinates.self, forKey: .coordinates)
        _rmUML = try container.decode(URL.self, forKey: .rmUML)
        _imagePath = try container.decode(URL.self, forKey: .imagePath)
        _physicalWidth = try container.decode(CGFloat.self, forKey: .physicalWidth)
    }
}
