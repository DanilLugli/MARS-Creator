//
//  File.swift
//  ScanBuild
//
//  Created by Danil Lugli on 29/07/24.
//

import Foundation
import SceneKit
import SwiftUI

class VisualizeRoomViewContainer: UIView {
    var sceneView: SceneView?
    var delegate = RenderDelegate()
    var scene = SCNScene()
    
    func setup(_ cameraNode: SCNNode, _ url: URL) {
      
        scene = try! SCNScene(url: url)
        cameraNode.camera = SCNCamera()
        
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
           
        _ = scene.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! == "Wall0"
            })[0]
        cameraNode.position = SCNVector3(scene.rootNode.simdPosition.x, 10, scene.rootNode.simdPosition.z)

        let vConstraint = SCNLookAtConstraint(target: scene.rootNode)
        cameraNode.constraints = [vConstraint]
        sceneView = SceneView(
            scene: scene,
            pointOfView: cameraNode,
            options: [.allowsCameraControl,.autoenablesDefaultLighting],
            //orthographicProjection ? [] : [.allowsCameraControl,.autoenablesDefaultLighting],
            delegate: self.delegate
        )
    }
}

class RenderDelegate: NSObject, SCNSceneRendererDelegate {

    var lastRenderer: SCNSceneRenderer!
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        lastRenderer = renderer
    }
}

