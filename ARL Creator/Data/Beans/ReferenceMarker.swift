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
    
    private let jsonFileName = "Marker Data.json"
    
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
        if let imageData = try? Data(contentsOf: _imagePath),
           let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "photo")
        }
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
            
            
            if let markerData = markersData[_imageName] {
                _imageName = markerData.name
                _physicalWidth = markerData.width
            }
        } catch {
            print("Errore nella lettura del file JSON: \(error)")
        }
    }
    
    public func saveMarkerData(to fileURL: URL, old oldName: String, new newName: String, size newWidth: CGFloat) {
        let referenceMarkerURL = fileURL.deletingLastPathComponent()
        var markersData: [String: MarkerData] = [:]
        let fileManager = FileManager.default


        let oldNameWithoutExtension = URL(fileURLWithPath: oldName).deletingPathExtension().lastPathComponent
        let newNameWithoutExtension = URL(fileURLWithPath: newName).deletingPathExtension().lastPathComponent

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                markersData = try decoder.decode([String: MarkerData].self, from: data)
            } catch {
                print("Errore nella lettura del file JSON esistente: \(error)")
            }
        }

        if oldNameWithoutExtension == newNameWithoutExtension {
            if var existingMarker = markersData[oldNameWithoutExtension] {
                existingMarker.width = newWidth
                markersData[oldNameWithoutExtension] = existingMarker
            } else {
                markersData[oldNameWithoutExtension] = MarkerData(name: newNameWithoutExtension, width: newWidth)
            }
        } else {

            if let fileWithExtension = try? fileManager.contentsOfDirectory(at: referenceMarkerURL, includingPropertiesForKeys: nil)
                .first(where: { $0.deletingPathExtension().lastPathComponent == oldNameWithoutExtension }) {

                let newFileURL = fileWithExtension.deletingLastPathComponent()
                    .appendingPathComponent(newNameWithoutExtension)
                    .appendingPathExtension(fileWithExtension.pathExtension)
                
                do {
                    try fileManager.moveItem(at: fileWithExtension, to: newFileURL)
                } catch {
                    print("Errore nel rinominare il file: \(error)")
                }
            } else {
                print("File con il nome \(oldNameWithoutExtension) non trovato.")
            }

            markersData.removeValue(forKey: oldNameWithoutExtension)
            markersData[newNameWithoutExtension] = MarkerData(name: newNameWithoutExtension, width: newWidth)
        }

        // Salva il JSON aggiornato senza estensioni nei nomi
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(markersData)
            try data.write(to: fileURL)
            print("File JSON aggiornato con successo!")
        } catch {
            print("Errore nel salvataggio del file JSON: \(error)")
        }
    }
    
    public func deleteMarkerData(from fileURL: URL, markerName: String) {
        let fileManager = FileManager.default
        var markersData: [String: MarkerData] = [:]

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                markersData = try decoder.decode([String: MarkerData].self, from: data)
            } catch {
                print("Errore nella lettura del file JSON esistente: \(error)")
                return
            }
        } else {
            print("File JSON non trovato a \(fileURL.path).")
            return
        }

        if markersData.removeValue(forKey: markerName) != nil {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(markersData)
                try data.write(to: fileURL)
                print("Marker \(markerName) eliminato correttamente dal file JSON.")
            } catch {
                print("Errore nel salvataggio del file JSON aggiornato: \(error)")
            }
        } else {
            print("Marker con il nome \(markerName) non trovato nel file JSON.")
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
