//
//  Rectangle.swift
//  ScanBuild
//
//  Created by Danil Lugli on 18/07/24.
//

import Foundation
import ARKit

struct Rectangle: Encodable {
    var origin: Coordinates
    var width: Float
    var height: Float

    var center: Coordinates {
        return Coordinates(x: origin.x + width / 2, y: origin.y + height / 2, z: 0)
    }
    
    var area: Float {
        return width * height
    }

    func contains(point: simd_float3) -> Bool {
        return point.x >= origin.x &&
               point.x <= origin.x + width &&
               point.y >= origin.y &&
               point.y <= origin.y + height
    }

    func overlaps(with other: Rectangle) -> Bool {
        return !(other.origin.x > origin.x + width ||
                 other.origin.x + other.width < origin.x ||
                 other.origin.y > origin.y + height ||
                 other.origin.y + other.height < origin.y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case origin
        case width
        case height
    }
}

