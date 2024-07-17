//
//  SCNViewContainer.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI
import SceneKit

struct SCNViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene(named: "example.scn")
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
