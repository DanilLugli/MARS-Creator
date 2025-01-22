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
