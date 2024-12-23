
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

    var handler = HandleTap()
    
    var delegate = RenderDelegate()
    
    var rotoTraslation: [RotoTraslationMatrix] = []
    @State var rotoTraslationActive: Int = 0
    
    init() {
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
    }
    
    func loadRoomPlanimetry(room: Room, borders: Bool) {
        
        scnView.scene = room.scene
        
        addDoorNodesBasedOnExistingDoors(room: room)
        drawSceneObjects(scnView: self.scnView, borders: borders)
        setMassCenter(scnView: self.scnView)
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
        createAxesNode()
        
    }
    
    func loadFloorPlanimetry(borders: Bool, floor: Floor) {

            scnView.scene = floor.scene
        drawSceneObjects(scnView: self.scnView, borders: borders)
        setMassCenter(scnView: self.scnView)
            setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
            createAxesNode()
            floor.isPlanimetryLoaded = true
    }
    
    func createAxesNode(length: CGFloat = 1.0, radius: CGFloat = 0.02) {
        let axisNode = SCNNode()
        
        // X Axis (Red)
        let xAxis = SCNNode(geometry: SCNCylinder(radius: radius, height: length))
        xAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        xAxis.position = SCNVector3(length / 2, 0, 0) // Offset by half length
        xAxis.eulerAngles = SCNVector3(0, 0, Float.pi / 2) // Rotate cylinder along X-axis
        
        // Y Axis (Green)
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
    
    func addDoorNodesBasedOnExistingDoors(room: Room) {
        
        let transitionNodes = room.sceneObjects?.filter{ node in
            if let nodeName = node.name {
                return (nodeName.hasPrefix("Door") || nodeName.hasPrefix("Opening"))
            }
            return false
        } ?? []
        
        for newTZNode in transitionNodes {
            
            let doorWidth = newTZNode.width
            let doorHeight = newTZNode.height
            var doorDepth = newTZNode.length
            let depthExtension: CGFloat = 0.6
            doorDepth += depthExtension
            var newDoorGeometry = SCNBox()
            
            newDoorGeometry = SCNBox(width: doorWidth, height: doorHeight, length: doorDepth, chamferRadius: 0.0)
            
            let newDoorNode = SCNNode(geometry: newDoorGeometry)
            
            newDoorNode.transform = newTZNode.transform
            
            let doorDirection = newTZNode.simdWorldFront
            let inwardTranslation = SIMD3<Float>(doorDirection * Float(doorDepth / 2))
            
            newDoorNode.simdPosition = newTZNode.simdPosition - inwardTranslation
            
            let nodeName = newTZNode.name != nil ? "TransitionZone_\(newTZNode.name!)" : "TransitionZone_Door"
            
            newDoorNode.name = nodeName
           
            scnView.scene?.rootNode.addChildNode(newDoorNode)
            
            let updateName = newDoorNode.name!.replacingOccurrences(of: "TransitionZone_", with: "")
            
            if !room.transitionZones.contains(where: { $0.name == updateName }) {
                let transitionZones = TransitionZone(name: updateName, connection: [Connection(name: "")])
                room.addTransitionZone(transitionZone: transitionZones)
                
            } else {
                print("Una TransitionZone con il nome \(nodeName) esiste già.")
            }
        }
    }
        
    func changeColorOfNode(nodeName: String, color: UIColor) {
        drawSceneObjects(scnView: self.scnView, borders: false)
        if let _node = scnView.scene?.rootNode.childNodes(passingTest: { n,_ in n.name != nil && n.name! == nodeName }).first {
            let copy = _node.copy() as! SCNNode
            copy.name = "__selected__"
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            copy.geometry?.materials = [material]
            copy.worldPosition.y += 4
            copy.scale.x = _node.scale.x < 0.2 ? _node.scale.x + 0.1 : _node.scale.x
            copy.scale.z = _node.scale.z < 0.2 ? _node.scale.z + 0.1 : _node.scale.z
            scnView.scene?.rootNode.addChildNode(copy)
        }
    }
    
    func resetColorNode() {
        // Trova tutti i nodi nella scena con il prefisso "__selected__"
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
            n.name?.hasPrefix("__selected__") ?? false
        }) {
            // Rimuove ogni nodo trovato dalla scena
            for node in nodes {
                node.removeFromParentNode()
            }
        } else {
            print("No nodes with prefix '__selected__' found.")
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        
        handler.scnView = scnView
        
        // Aggiunta del riconoscitore di pinch per lo zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        // Aggiunta del riconoscitore di pan per lo spostamento
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
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
                camera.orthographicScale = max(5.0, min(newScale, 50.0)) // Limita lo zoom tra 5x e 50x
                gesture.scale = 1
            }
        }
        
        // Gestione dello spostamento tramite pan
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.scnView)
            
            // Regola la posizione della camera in base alla direzione del pan
            parent.cameraNode.position.x -= Float(translation.x) * 0.01 // Spostamento orizzontale
            parent.cameraNode.position.z += Float(translation.y) * 0.01 // Spostamento verticale
            
            // Resetta la traduzione dopo ogni movimento
            gesture.setTranslation(.zero, in: parent.scnView)
        }
    }
}
