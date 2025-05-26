//
//  Extension.swift
//  ScanBuild
//
//  Created by Danil Lugli on 27/11/24.
//

import Foundation
import SwiftUI
import SceneKit
import ComplexModule



extension Color {
    static let appBackground = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let primaryText = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let accentBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    func toUIColor() -> UIColor {
        let uiColor = UIColor(self)
        return uiColor
    }
}

extension Notification.Name {
    static var genericMessage: Notification.Name {
        return .init(rawValue: "genericMessage.message")
    }
    static var genericMessage2: Notification.Name {
        return .init(rawValue: "genericMessage.message2")
    }
    static var genericMessage3: Notification.Name {
        return .init(rawValue: "genericMessage.message3")
    }
    static var trackingState: Notification.Name {
        return .init(rawValue: "trackingState.message")
    }
    static var timeLoading: Notification.Name {
        return .init(rawValue: "timeLoading.message")
    }
    static var worldMapMessage: Notification.Name {
        return .init(rawValue: "WorldMapMessage.message")
    }
    static var worldMapCounter: Notification.Name {
        return .init(rawValue: "WorldMapMessage.counter")
    }
    
    static var trackingPosition: Notification.Name {
        return .init(rawValue: "trackingPosition.message")
    }
    
    static var worldMapNewFeatures: Notification.Name {
        return .init(rawValue: "worlMapNewFeatures.message")
    }
    
    static var trackingPositionFromMotionManager: Notification.Name {
        return .init(rawValue: "trackingPositionFromMotionManager.message")
    }
    
}

extension SCNQuaternion {
    func difference(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w
        )
    }
    
    func sum(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w
        )
    }
}

extension SCNVector3 {
    func difference(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z
        )
    }
    
    func sum(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z
        )
    }
    
    func rotateAroundOrigin(_ angle: Float) -> SCNVector3 {
        var a = Complex<Float>.i
        a.real = cos(angle)
        a.imaginary = sin(angle)
        var b = Complex<Float>.i
        b.real = self.x
        b.imaginary = self.z
        let position = a*b
        return SCNVector3(
            position.real,
            self.y,
            position.imaginary
        )
    }
}

extension SCNNode {
    
    var height: CGFloat { CGFloat(self.boundingBox.max.y - self.boundingBox.min.y) }
    var width: CGFloat { CGFloat(self.boundingBox.max.x - self.boundingBox.min.x) }
    var depth: CGFloat { CGFloat(self.boundingBox.max.z - self.boundingBox.min.z) }
    
    var halfCGHeight: CGFloat { height / 2.0 }
    var halfHeight: Float { Float(height / 2.0) }
    var halfScaledHeight: Float { halfHeight * self.scale.y  }
    
    // Proprietà che restituisce il volume del nodo basandosi sul suo `boundingBox`
    var volume: CGFloat {
        return self.height * self.width * self.depth
    }
    
    // Proprietà che calcola il tipo di nodo a partire dal suo nome
    var type: String? {
        guard let name = self.name else {
            return nil
        }
        
        let pattern = "(?:^clone_)+|\\d+$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        return regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
    }
}

extension simd_float3 {
    
    // Metodo per applicare la trasformazione a un punto
    func transformXZ(rotationAngle: Float = 0, translation: simd_float3 = simd_float3(0, 0, 0)) -> simd_float3 {
        let cosTheta = cos(rotationAngle)
        let sinTheta = sin(rotationAngle)
        
        // Matrice di rotazione attorno all'asse y
        let rotationMatrix = simd_float3x3(
            simd_float3(cosTheta, 0, sinTheta),
            simd_float3(0, 1, 0),
            simd_float3(-sinTheta, 0, cosTheta)
        )
        
        // Applica rotazione e poi traslazione
        let rotated = rotationMatrix.transpose * self
        return rotated + translation
    }
}

extension Array where Element == SCNNode {
    
    // Metodo che converte un array di nodi in un array di `simd_float3`,
    // ognuno dei quali rappresenta la posizione mondiale (world position)
    // del nodo corrispondente, utilizzando la proprietà `simdWorldPosition`.
    var simdWorldPositions: [simd_float3] {
        return self.map { $0.simdWorldPosition }
    }
}

extension Array where Element == simd_float3 {
    
    // Metodo per calcolare il centroide di un array di punti
    func getCentroid() -> simd_float3 {
        var sum = simd_float3(0, 0, 0)
        for point in self {
            sum += point
        }
        return sum / Float(self.count)
    }
    
    // Metodo per calcolare la matrice delle distanze
    func getDistanceMatrix() -> [[Float]] {
        var distanceMatrix: [[Float]] = Array<[Float]>(
            repeating: Array<Float>(repeating: 0.0, count: self.count),
            count: self.count
        )
        
        for (i, row) in distanceMatrix.enumerated() {
            for (j, _) in row.enumerated() where j > i {
                distanceMatrix[i][j] = simd.distance(self[i], self[j])
                distanceMatrix[j][i] = distanceMatrix[i][j]
            }
        }
        
        return distanceMatrix
    }
    
    // Metodo per calcolare le altezze relative
    func getRelativeHeights() -> [Float] {
        let minY = self.map { $0.y }.min()!
        return self.map { $0.y - minY }
    }
}

extension Array {
    
    // Metodo per calcolare le permutazioni a un array
    func permutations() -> [[Element]] {
        guard count > 0 else { return [[]] }
        
        return indices.flatMap { i -> [[Element]] in
            var rest = self
            let element = rest.remove(at: i)
            return rest.permutations().map { [element] + $0 }
        }
    }
    
    // Metodo per calcolare le combinazioni di grandezza k di un array
    func combinations(taking k: Int) -> [[Element]] {
        guard k > 0 else { return [[]] }
        guard k <= self.count else { return [] }

        if k == self.count {
            return [self]
        }

        if k == 1 {
            return self.map { [$0] }
        }

        var result: [[Element]] = []

        for (i, element) in self.enumerated() {
            let remaining = Array(self[(i + 1)...])
            let subcombinations = remaining.combinations(taking: k - 1)
            result += subcombinations.map { [element] + $0 }
        }

        return result
    }
}
