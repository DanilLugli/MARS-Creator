//
//  ARSCNViewContainer.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI
import ARKit

struct ARSCNViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session.run(ARWorldTrackingConfiguration())
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
