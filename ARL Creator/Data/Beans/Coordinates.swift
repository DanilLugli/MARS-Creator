//
//  Coordinates.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation
import simd

class Coordinates: Codable {
    var position: simd_float3

    init(x: Float, y: Float, z: Float) {
        self.position = simd_float3(x, y, z)
    }
    
    // Proprietà per accedere ai valori individualmente
    var x: Float {
        get { return position.x }
        set { position.x = newValue }
    }
    
    var y: Float {
        get { return position.y }
        set { position.y = newValue }
    }
    
    var z: Float {
        get { return position.z }
        set { position.z = newValue }
    }
    
    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case x, y, z
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Float.self, forKey: .x)
        let y = try container.decode(Float.self, forKey: .y)
        let z = try container.decode(Float.self, forKey: .z)
        self.position = simd_float3(x, y, z)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(position.x, forKey: .x)
        try container.encode(position.y, forKey: .y)
        try container.encode(position.z, forKey: .z)
    }
}
