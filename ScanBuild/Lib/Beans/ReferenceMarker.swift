//
//  ReferenceMarker.swift
//  ScanBuild
//
//  Created by Danil Lugli on 10/07/24.
//

import Foundation
import SwiftUI

class ReferenceMarker: Codable, Identifiable {
    private var _id: UUID = UUID()
    private var _image: Image? = nil
    private var _imagePath : URL
    private var _imageName: String
    private var _coordinates: Coordinates
    private var _rmUML: URL
    
    init(_imagePath: URL, _imageName: String, _coordinates: Coordinates, _rmUML: URL) {
        self._imagePath = _imagePath
        self._imageName = _imageName
        self._coordinates = _coordinates
        self._rmUML = _rmUML
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
                    _image = Image(systemName: "photo") // Placeholder image in case of failure
                }
            }
            return _image!
        }
    
    var imageName: String {
        return _imageName
    }
    
    var coordinates: Coordinates {
        return _coordinates
    }
    
    var rmUML: URL {
        return _rmUML
    }
    
    // Implementazione personalizzata di Codable
        private enum CodingKeys: String, CodingKey {
            case id
            case imageName
            case coordinates
            case rmUML
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(_id, forKey: .id)
            try container.encode(_imageName, forKey: .imageName)
            try container.encode(_coordinates, forKey: .coordinates)
            try container.encode(_rmUML, forKey: .rmUML)
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            _id = try container.decode(UUID.self, forKey: .id)
            _imageName = try container.decode(String.self, forKey: .imageName)
            _coordinates = try container.decode(Coordinates.self, forKey: .coordinates)
            _rmUML = try container.decode(URL.self, forKey: .rmUML)
            _imagePath = URL(string: _imageName)!
        }
}

