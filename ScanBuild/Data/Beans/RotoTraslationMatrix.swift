import Foundation
import simd

// RotoTraslationMatrix and SIMDMatrix4x4 implementations
struct RotoTraslationMatrix: Codable {
    let name: String
    let translation: SIMDMatrix4x4
    let r_Y: SIMDMatrix4x4


    init(name: String, translation: simd_float4x4, r_Y: simd_float4x4) {
        self.name = name
        self.translation = SIMDMatrix4x4(matrix: translation)
        self.r_Y = SIMDMatrix4x4(matrix: r_Y)
    }
    

    private enum CodingKeys: String, CodingKey {
        case translation, r_Y, name
    }
}

struct SIMDMatrix4x4: Codable {
    var matrix: simd_float4x4

    init(matrix: simd_float4x4) {
        self.matrix = matrix
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var matrix = simd_float4x4()
        for row in 0..<4 {
            for col in 0..<4 {
                matrix[row][col] = try container.decode(Float.self)
            }
        }
        self.matrix = matrix
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for row in 0..<4 {
            for col in 0..<4 {
                try container.encode(matrix[row][col])
            }
        }
    }
}
