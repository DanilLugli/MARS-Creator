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

func loadRoomPositionFromJson(from fileURL: URL) -> [String: RotoTraslationMatrix]? {
    do {
        // Leggi il contenuto del file JSON
        let data = try Data(contentsOf: fileURL)
        
        // Effettua il parsing del JSON in un dizionario
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDict = jsonObject as? [String: [String: [[Double]]]] else {
            print("Invalid JSON format")
            return nil
        }
        
        // Dizionario per memorizzare i risultati
        var associationMatrix: [String: RotoTraslationMatrix] = [:]
        
        // Cicla attraverso ogni voce del dizionario
        for (roomName, matrices) in jsonDict {
            // Estrai le matrici di rotazione e traslazione
            guard let translationMatrix = matrices["translation"],
                  let r_YMatrix = matrices["R_Y"],
                  translationMatrix.count == 4,
                  r_YMatrix.count == 4 else {
                print("Invalid JSON structure for room: \(roomName)")
                continue
            }
            
            // Converti i valori in matrici `simd_float4x4`
            let translation = simd_float4x4(rows: translationMatrix.map { simd_float4($0.map { Float($0) }) })
            let r_Y = simd_float4x4(rows: r_YMatrix.map { simd_float4($0.map { Float($0) }) })
            
            // Crea un oggetto `RotoTraslationMatrix`
            let rotoTraslationMatrix = RotoTraslationMatrix(name: roomName, translation: translation, r_Y: r_Y)
            
            // Aggiungi l'oggetto al dizionario
            associationMatrix[roomName] = rotoTraslationMatrix
        }
        
        return associationMatrix
        
    } catch {
        print("Error loading or parsing JSON: \(error)")
        return nil
    }
}
