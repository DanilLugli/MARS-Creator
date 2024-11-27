//
//  Utils.swift
//  ScanBuild
//
//  Created by Danil Lugli on 06/08/24.
//

import Foundation
import SceneKit

func printNodeHierarchy(_ node: SCNNode, indent: String = "") {
    // Stampa il nome del nodo o "Unnamed node" se non ha un nome
    print("\(indent)\(node.name ?? "Unnamed node")")
    
    // Ricorsivamente stampa i nodi figli
    for child in node.childNodes {
        printNodeHierarchy(child, indent: indent + "  ")  // Aggiunge uno spazio per ogni livello
    }
}

//@MainActor func processRooms(for floor: Floor) {
//    for room in floor.rooms {
//        let roomScene = room.scene
//        
//        if let roomNode = roomScene?.rootNode.childNode(withName: "Floor0", recursively: true) {
//            let originalScale = roomNode.scale
//            let roomName = room.name
//            
//            roomNode.simdWorldPosition = simd_float3(0, 0, 0)
//            roomNode.scale = originalScale
//            
//            if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
//                applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
//            } else {
//                print("No RotoTraslationMatrix found for room: \(roomName)")
//            }
//            
//            roomNode.name = roomName
//            let material = SCNMaterial()
//            material.diffuse.contents = floor.getRoomByName(roomName)?.color
//            roomNode.geometry?.materials = [material]
//            
//            floor.scene?.rootNode.addChildNode(roomNode)
//        } else {
//            print("Node 'Floor0' not found in scene: \(String(describing: roomScene))")
//        }
//    }
//    
//
//    /// Applica una rototraslazione a un nodo SCNNode.
//    /// - Parameters:
//    ///   - node: Il nodo da trasformare.
//    ///   - rotoTraslation: La matrice di rototraslazione contenente traslazione e rotazione.
//    ///   - baseTransform: (Opzionale) Una matrice di trasformazione base. Default: utilizza la trasformazione attuale del nodo.
//    @MainActor
//    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
//        
//        let translationVector = simd_float3(
//            rotoTraslation.translation.columns.3.x,
//            rotoTraslation.translation.columns.3.y,
//            rotoTraslation.translation.columns.3.z
//        )
//        node.simdPosition = node.simdPosition + translationVector
//        
//        let rotationMatrix = rotoTraslation.r_Y
//        
//        let rotationQuaternion = simd_quatf(rotationMatrix)
//        
//        node.simdOrientation = rotationQuaternion * node.simdOrientation
//        
//    }
//}
