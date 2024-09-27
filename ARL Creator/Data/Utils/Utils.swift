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
