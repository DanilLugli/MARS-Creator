import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

struct SCNViewContainer: UIViewRepresentable {
    
    
    typealias UIViewType = SCNView
    
    var scnView = SCNView(frame: .zero)
    var origin = SCNNode()
    var massCenter = SCNNode()
    var cameraNode = SCNNode()
    var dimension = SCNVector3()
    
    var delegate = RenderDelegate()
    
    var rotoTraslation: [RoomPositionMatrix] = []
    @State var rotoTraslationActive: Int = 0
    
    init(empty: Bool = false) {
        if !empty {
            massCenter.worldPosition = SCNVector3(0, 0, 0)
            origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
        }
    }
    
    @MainActor
    func loadRoomPlanimetry(room: Room, borders: Bool) {
        let scene = room.scene
        
        self.scnView.scene = scene
        drawSceneObjects(scnView: self.scnView, borders: borders, nodeOrientation: false)
        
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: setMassCenter(scnView: self.scnView))
        //        createAxesNode()
        
    }
    
    @MainActor
    func loadFloorPlanimetry(borders: Bool, floor: Floor) {
        
        let scene = floor.scene
        
        self.scnView.scene = scene
        drawSceneObjects(scnView: self.scnView, borders: borders, nodeOrientation: false)
        //        createAxesNode()
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: setMassCenter(scnView: self.scnView))
        floor.isPlanimetryLoaded = true
    }
    
    
    func createAxesNode(length: CGFloat = 1.0, radius: CGFloat = 0.02) {
        let axisNode = SCNNode()
        
        let xAxis = SCNNode(geometry: SCNCylinder(radius: radius, height: length))
        xAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        xAxis.position = SCNVector3(length / 2, 0, 0) // Offset by half length
        xAxis.eulerAngles = SCNVector3(0, 0, Float.pi / 2) // Rotate cylinder along X-axis
        
        let yAxis = SCNNode(geometry: SCNCylinder(radius: radius, height: length))
        yAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        yAxis.position = SCNVector3(0, length / 2, 0) // Offset by half length
        
        // Z Axis (Blue)
        let zAxis = SCNNode(geometry: SCNCylinder(radius: radius, height: length))
        zAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        zAxis.position = SCNVector3(0, 0, length / 2) // Offset by half length
        zAxis.eulerAngles = SCNVector3(Float.pi / 2, 0, 0) // Rotate cylinder along Z-axis
        
        // Add axes to parent node
        axisNode.addChildNode(xAxis)
        axisNode.addChildNode(yAxis)
        axisNode.addChildNode(zAxis)
        self.scnView.scene?.rootNode.addChildNode(axisNode)
        
    }
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        guard let scene = scnView.scene else {
            return
        }
        
        let allNodes = scene.rootNode.childNodes { _, _ in true } // Closure valida
        
        
        guard let originalNode = scnView.scene?.rootNode.childNode(withName: nodeName, recursively: true) else {
            return
        }
        
        let clonedNode = originalNode.clone()
        
        if let originalGeometry = originalNode.geometry {
            clonedNode.geometry = originalGeometry.copy() as? SCNGeometry
        }
        
        clonedNode.name = "__selected__"
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        
        clonedNode.geometry?.materials = [material]
        
        clonedNode.worldPosition.y += 4
        
        if clonedNode.scale.x < 0.2 {
            clonedNode.scale.x += 0.1
        }
        if clonedNode.scale.z < 0.2 {
            clonedNode.scale.z += 0.1
        }
        
        scnView.scene?.rootNode.addChildNode(clonedNode)
        
    }
    
    func resetColorNode() {
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
            n.name?.hasPrefix("__selected__") ?? false
        }) {
            for node in nodes {
                node.removeFromParentNode()
            }
        } else {
            print("No nodes with prefix '__selected__' found.")
        }
    }
    
    func makeCoordinator() -> SCNViewGestureCoordinator {
        SCNViewGestureCoordinator(scnView: scnView, cameraNode: cameraNode)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let coordinator = context.coordinator

        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePinch(_:)))
        pinch.delegate = coordinator
        scnView.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePan(_:)))
        pan.delegate = coordinator
        scnView.addGestureRecognizer(pan)

        let rotate = UIRotationGestureRecognizer(target: coordinator, action: #selector(coordinator.handleRotation(_:)))
        rotate.delegate = coordinator
        scnView.addGestureRecognizer(rotate)

        scnView.backgroundColor = .white
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
