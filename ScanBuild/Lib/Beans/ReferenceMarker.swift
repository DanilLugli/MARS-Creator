//
//  ReferenceMarker.swift
//  ScanBuild
//
//  Created by Danil Lugli on 10/07/24.
//

import Foundation
import SwiftUI

import Foundation
import SwiftUI

class ReferenceMarker: Codable {
    private var _id: UUID
    private var _image: Image
    private var _imageName: String
    private var _coordinates: Coordinates
    private var _rmUML: URL
    
    init(id: UUID, image: Image, imageName: String, coordinates: Coordinates, rmUML: URL) {
        self._id = id
        self._image = image
        self._imageName = imageName
        self._coordinates = coordinates
        self._rmUML = rmUML
    }
    
    var id: UUID {
        return _id
    }
    
    var image: Image {
        return _image
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
        
        // Placeholder value for the image
        _image = Image("")
    }
    
    // JSON Serialization using Codable
    func toJSON() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    static func fromJSON(_ jsonString: String) -> ReferenceMarker? {
        if let jsonData = jsonString.data(using: .utf8) {
            return try? JSONDecoder().decode(ReferenceMarker.self, from: jsonData)
        }
        return nil
    }
}

//struct Coordinates: Codable {
//    var x: Double
//    var y: Double
//}
