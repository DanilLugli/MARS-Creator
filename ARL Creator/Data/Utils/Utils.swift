//
//  Utils.swift
//  ScanBuild
//
//  Created by Danil Lugli on 06/08/24.
//

import Foundation
import SceneKit

func printNodeHierarchy(_ node: SCNNode, indent: String = "") {
    print("\(indent)\(node.name ?? "Unnamed node")")
    
    for child in node.childNodes {
        printNodeHierarchy(child, indent: indent + "  ")  
    }
}

func debugNodeProperties(_ node: SCNNode) {
    let position = node.simdWorldPosition
    let scale = node.scale
    let eulerAngles = node.eulerAngles

    // Converti gli angoli di rotazione da radianti a gradi
    let rotationXInDegrees = eulerAngles.x * 180 / .pi
    let rotationYInDegrees = eulerAngles.y * 180 / .pi
    let rotationZInDegrees = eulerAngles.z * 180 / .pi

    print("\nDEBUG: Node Properties for \(node.name ?? "Unnamed Node")")
    print("Position:")
    print("  x: \(position.x), y: \(position.y), z: \(position.z)")
    print("Scale:")
    print("  x: \(scale.x), y: \(scale.y), z: \(scale.z)")
    print("Rotation (Euler Angles in Radians):")
    print("  x: \(eulerAngles.x), y: \(eulerAngles.y), z: \(eulerAngles.z)")
    print("Rotation (Euler Angles in Degrees):")
    print("  x: \(rotationXInDegrees), y: \(rotationYInDegrees), z: \(rotationZInDegrees)")
    print("Rotation Y (Euler Angles in Degrees):")
    print(" y: \(rotationYInDegrees)")
}

func printMatrix(_ matrix: simd_float4x4, label: String = "Matrix") {
    print("\(label):")
    for row in 0..<4 {
        let rowValues = SIMD4(matrix.columns.0[row],
                              matrix.columns.1[row],
                              matrix.columns.2[row],
                              matrix.columns.3[row])
        print(String(format: "[ %.6f, %.6f, %.6f, %.6f ]",
                     rowValues.x, rowValues.y, rowValues.z, rowValues.w))
    }
    print("\n")
}

func loadRoomPositionFromJson(from fileURL: URL, for floor: Floor) -> [String: RoomPositionMatrix]? {
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
        var associationMatrix: [String: RoomPositionMatrix] = [:]
        
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
            let rotoTraslationMatrix = RoomPositionMatrix(name: roomName, translation: translation, r_Y: r_Y)
            
            // Aggiungi l'oggetto al dizionario
            associationMatrix[roomName] = rotoTraslationMatrix
            floor.getRoomByName(roomName)?.hasPosition = doesMatrixExist(for: roomName, in: associationMatrix)
        }
        
        return associationMatrix
        
    } catch {
        print("Error loading or parsing JSON: \(error)")
        return nil
    }
}

/// Funzione helper che restituisce la riga `row` della matrice 4x4.
/// Poiché la matrice è organizzata in colonne, la riga viene ricostruita estraendo l'elemento `row` da ciascuna colonna.
func getRow(from matrix: simd_float4x4, row: Int) -> simd_float4 {
    return simd_float4(matrix.columns.0[row],
                       matrix.columns.1[row],
                       matrix.columns.2[row],
                       matrix.columns.3[row])
}

/// Verifica se esiste una voce per la room data in `associationMatrix`.
/// Prima di restituire il risultato, stampa il contenuto di ogni voce (nome, translation e r_Y).
func doesMatrixExist(for roomName: String, in associationMatrix: [String: RoomPositionMatrix]) -> Bool {
    print("Contenuto di associationMatrix:")
    
    for (_, matrixStruct) in associationMatrix {
        print("Room Name: \(matrixStruct.name)")
        
        // 🔹 Stampa la matrice di traslazione
        print("Translation Matrix:")
        for i in 0..<4 {
            let row = getRow(from: matrixStruct.translation, row: i)
            let rowString = String(format: "[%.2f, %.2f, %.2f, %.2f]", row.x, row.y, row.z, row.w)
            print(rowString)
        }
        
        print("Rotation Y Matrix:")
        for i in 0..<4 {
            let row = getRow(from: matrixStruct.r_Y, row: i)
            let rowString = String(format: "[%.2f, %.2f, %.2f, %.2f]", row.x, row.y, row.z, row.w)
            print(rowString)
        }
        print("-----")
    }
    
    guard let matrixStruct = associationMatrix[roomName] else {
        print("RESULT: false (la matrice non esiste)")
        return false
    }
    
    let isTranslationIdentity = isIdentityMatrix(matrixStruct.translation)
    let isRotationIdentity = isIdentityMatrix(matrixStruct.r_Y)
    
    if isTranslationIdentity && isRotationIdentity {
        print("RESULT: false (la matrice esiste, ma entrambe sono matrici identità)")
        return false
    }
    
    print("RESULT: true (la matrice esiste ed è valida)")
    return true
}

func isIdentityMatrix(_ matrix: simd_float4x4) -> Bool {
    let identity = matrix_identity_float4x4
    return matrix == identity
}

func clearJSONFile(at fileURL: URL) {
    let emptyDictionary: [String: Any] = [:]
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: emptyDictionary, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
        print("Il file JSON è stato cancellato e ora contiene: \(String(data: jsonData, encoding: .utf8) ?? "")")
    } catch {
        print("Errore durante la cancellazione del file JSON: \(error)")
    }
}

func removeRoomPositionKeyJSON(from jsonFileURL: URL, roomName: String) {
    let fileManager = FileManager.default
    
    // Verifica se il file esiste
    guard fileManager.fileExists(atPath: jsonFileURL.path) else {
        print("Il file JSON non esiste a: \(jsonFileURL.path)")
        return
    }
    
    do {
        // Leggi i dati JSON dal file
        let jsonData = try Data(contentsOf: jsonFileURL)
        
        // Deserializza in un dizionario
        if var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            
            // Rimuovi la chiave corrispondente a roomName
            jsonDict.removeValue(forKey: roomName)
            
            // Serializza nuovamente il dizionario in JSON
            let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            
            // Scrivi i dati aggiornati sul file
            try updatedJsonData.write(to: jsonFileURL)
            print("La chiave '\(roomName)' è stata rimossa correttamente.")
        } else {
            print("Il contenuto del file non è nel formato atteso ([String: Any]).")
        }
    } catch {
        print("Errore durante la lettura o scrittura del file JSON: \(error.localizedDescription)")
    }
}


