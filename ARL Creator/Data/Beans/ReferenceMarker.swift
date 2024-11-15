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
    private var _imagePath : URL
    @Published private var _imageName: String
    private var _coordinates: Coordinates
    private var _rmUML: URL
    @Published private var _physicalWidth: CGFloat

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
        get {
            return _imageName
        }
        set {
            _imageName = newValue
        }
    }

    var coordinates: Coordinates {
        return _coordinates
    }

    var rmUML: URL {
        return _rmUML
    }

    var physicalWidth: CGFloat {
        get {
            return _physicalWidth
        }
        set {
            _physicalWidth = newValue
        }
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
        case id
        case imageName
        case coordinates
        case rmUML
        case imagePath
        case physicalWidth
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
