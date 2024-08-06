import Foundation
import simd

struct RotoTraslationMatrix: Codable {
    let name: String
    let translation: simd_float4x4
    let r_Y: simd_float4x4

    init(name: String, translation: simd_float4x4, r_Y: simd_float4x4) {
        self.name = name
        self.translation = translation
        self.r_Y = r_Y
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, translation, r_Y
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        translation = try container.decode(SIMDMatrix4x4.self, forKey: .translation).matrix
        r_Y = try container.decode(SIMDMatrix4x4.self, forKey: .r_Y).matrix
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(SIMDMatrix4x4(matrix: translation), forKey: .translation)
        try container.encode(SIMDMatrix4x4(matrix: r_Y), forKey: .r_Y)
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

func loadRotoTraslationMatrix(from fileURL: URL) -> [RotoTraslationMatrix]? {
    do {
        let data = try Data(contentsOf: fileURL)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDict = jsonObject as? [String: [String: [[Double]]]] else {
            print("Invalid JSON format")
            return nil
        }
        
        var rotoTraslationMatrices: [RotoTraslationMatrix] = []
        
        for (key, value) in jsonDict {
            guard let translationMatrix = value["translation"],
                  let r_YMatrix = value["R_Y"],
                  translationMatrix.count == 4,
                  r_YMatrix.count == 4 else {
                print("Invalid JSON structure for key: \(key)")
                continue
            }
            
            let translation = simd_float4x4(rows: translationMatrix.map { simd_float4($0.map { Float($0) }) })
            let r_Y = simd_float4x4(rows: r_YMatrix.map { simd_float4($0.map { Float($0) }) })
            
            let rotoTraslationMatrix = RotoTraslationMatrix(name: key, translation: translation, r_Y: r_Y)
            rotoTraslationMatrices.append(rotoTraslationMatrix)
        }
        
        return rotoTraslationMatrices
        
    } catch {
        print("Error loading or parsing JSON: \(error)")
        return nil
    }
}
