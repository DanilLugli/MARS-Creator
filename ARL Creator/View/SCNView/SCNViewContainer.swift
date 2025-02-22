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
            print("⚠️ Scene is nil.")
            return
        }
        
        // Stampa tutti i nodi disponibili nella scena
        let allNodes = scene.rootNode.childNodes { _, _ in true } // Closure valida
        print("🌲 Available nodes in scene:")
        for node in allNodes {
            print("- \(node.name ?? "Unnamed")")
        }
        
        
        guard let originalNode = scnView.scene?.rootNode.childNode(withName: nodeName, recursively: true) else {
            print("❌ Node \(nodeName) not found.")
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
        
        print("✅ Cloned node \(clonedNode.name ?? "Unnamed") added to scene!")
    }
    
    func resetColorNode() {
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
            n.name?.hasPrefix("__selected__") ?? false
        }) {
            for node in nodes {
                print("Nodo \(node.name ?? "PINO") eliminato!!")
                node.removeFromParentNode()
            }
        } else {
            print("No nodes with prefix '__selected__' found.")
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        
        // Riconoscitore di pinch per lo zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        // Riconoscitore di pan per lo spostamento
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        // Riconoscitore di rotazione per ruotare la scena con due dita
        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleRotation(_:)))
        scnView.addGestureRecognizer(rotationGesture)
        
        // Riconoscitore di tap per selezionare un nodo
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
//        scnView.addGestureRecognizer(tapGesture)
        
        // Configura lo sfondo della scena
        scnView.backgroundColor = UIColor.white
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> SCNViewContainerCoordinator {
        SCNViewContainerCoordinator(self)
    }
    
    class SCNViewContainerCoordinator: NSObject {
        var parent: SCNViewContainer
        
        init(_ parent: SCNViewContainer) {
            self.parent = parent
        }
        
        // Gestione dello zoom tramite pinch
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = parent.cameraNode.camera else { return }
            
            if gesture.state == .changed {
                let newScale = camera.orthographicScale / Double(gesture.scale)
                camera.orthographicScale = max(1.0, min(newScale, 200.0))
                gesture.scale = 1
            }
        }
        
        // Gestione del pan per lo spostamento
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.scnView)
            parent.cameraNode.position.x -= Float(translation.x) * 0.04
            parent.cameraNode.position.z -= Float(translation.y) * 0.04
            gesture.setTranslation(.zero, in: parent.scnView)
        }
        
        // Gestione della rotazione tramite due dita
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            // Ruota la camera attorno all'asse Y; se preferisci ruotare l'intera scena,
            // puoi applicare la trasformazione sul nodo radice della scena.
            if gesture.state == .changed {
                parent.scnView.scene?.rootNode.eulerAngles.y -= Float(gesture.rotation)
                gesture.rotation = 0
            }
        }
//
//        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
//            let location = gesture.location(in: parent.scnView)
//            let hitResults = parent.scnView.hitTest(location, options: nil)
//            if let hit = hitResults.first, let nodeName = hit.node.name {
//                print("Nodo toccato: \(nodeName)")
//                parent.changeColorOfNode(nodeName: nodeName, color: UIColor.green)
//            }
//        }
    }
}
