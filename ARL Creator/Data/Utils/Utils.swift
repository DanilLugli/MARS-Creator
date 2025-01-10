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
