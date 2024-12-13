
import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

struct SCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = SCNView
    
    var scnView = SCNView(frame: .zero)
    var handler = HandleTap()
    
    var cameraNode = SCNNode()
    var massCenter = SCNNode()
    var delegate = RenderDelegate()
    var dimension = SCNVector3()
    
    var rotoTraslation: [RotoTraslationMatrix] = []
    var origin = SCNNode()
    @State var rotoTraslationActive: Int = 0
    
    init() {
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
    }
    
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.camera = SCNCamera()
        
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
        
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 20
        
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        
        cameraNode.constraints = []
    }
    
    func setCameraUp() {
        cameraNode.camera = SCNCamera()
        
        // Add the camera node to the scene
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        // Position the camera at the same Y level as the mass center, and at a certain distance along the Z-axis
        let cameraDistance: Float = 10.0 // Distance in front of the mass center
        let cameraHeight: Float = massCenter.worldPosition.y + 2.0 // Slightly above the mass center
        
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, cameraHeight, massCenter.worldPosition.z + cameraDistance)
        
        // Set the camera to use perspective projection
        cameraNode.camera?.usesOrthographicProjection = false
        
        // Optionally set the field of view
        cameraNode.camera?.fieldOfView = 60.0 // Adjust as needed
        
        // Make the camera look at the mass center
        let lookAtConstraint = SCNLookAtConstraint(target: massCenter)
        lookAtConstraint.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAtConstraint]
        
        // Add ambient light to the scene
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.5, alpha: 1.0)
        scnView.scene?.rootNode.addChildNode(ambientLight)
        
        // Add a directional light to simulate sunlight
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .directional
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0) // Adjust angle as needed
        scnView.scene?.rootNode.addChildNode(directionalLight)
        
        // Set the point of view of the scene to the camera node
        scnView.pointOfView = cameraNode
    }
    
    func drawSceneObjects(borders: Bool) {
        
        var drawnNodes = Set<String>()
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: { n, _ in
                n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Floor0" &&
                n.name! != "Geom" &&
                String(n.name!.suffix(4)) != "_grp" &&
                n.name! != "__selected__"
            })
            .forEach {
                let nodeName = $0.name
                let material = SCNMaterial()
                if nodeName == "Floor0" {
                    material.diffuse.contents = UIColor.green
                } else {
                    material.diffuse.contents = UIColor.black
                    if nodeName?.prefix(5) == "Floor" {
                        material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
                    }
                    if nodeName!.prefix(6) == "Transi" {
                        material.diffuse.contents = UIColor.white
                    }
                    if nodeName!.prefix(4) == "Door" {
                        material.diffuse.contents = UIColor.white
                    }
                    if nodeName!.prefix(4) == "Open"{
                        material.diffuse.contents = UIColor.systemGray5
                    }
                    if nodeName!.prefix(4) == "Tabl" {
                        material.diffuse.contents = UIColor.brown
                    }
                    if nodeName!.prefix(4) == "Chai"{
                        material.diffuse.contents = UIColor.brown.withAlphaComponent(0.4)
                    }
                    if nodeName!.prefix(4) == "Stor"{
                        material.diffuse.contents = UIColor.systemGray
                    }
                    if nodeName!.prefix(4) == "Sofa"{
                        material.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 0.6)
                    }
                    if nodeName!.prefix(4) == "Tele"{
                        material.diffuse.contents = UIColor.orange
                    }
                    material.lightingModel = .physicallyBased
                    $0.geometry?.materials = [material]
                    
                    if borders {
                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                        $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                    }
                }
                drawnNodes.insert(nodeName!)
            }
    }
    
    func loadRoomPlanimetry(room: Room, borders: Bool) {
        
        scnView.scene = room.scene
        
        if (scnView.scene?.rootNode) != nil {
            //print("NODE HIERARCHY FOR \(room.name)")
            //printNodeHierarchy(rootNode)
        }
        
        addDoorNodesBasedOnExistingDoors(room: room)
        drawSceneObjects(borders: borders)
        setMassCenter()
        setCamera()
        createAxesNode()
        
    }
    
    func loadFloorPlanimetry(borders: Bool, floor: Floor) {

            scnView.scene = floor.scene
            drawSceneObjects(borders: borders)
            setMassCenter()
            setCamera()
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
            
            print(newTZNode.name! + "\n")
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
                print("AGGIUNGO \(updateName)")
                let transitionZones = TransitionZone(name: updateName, connection: [Connection(name: "")])
                room.addTransitionZone(transitionZone: transitionZones)
                
            } else {
                print("Una TransitionZone con il nome \(nodeName) esiste già.")
            }
            print("Nuova porta aggiunta alla scena con nome \(newDoorNode.name!).")
        }
    }
    
    func setMassCenter() {
        if let massCenter = findMassCenter() {
            scnView.scene?.rootNode.addChildNode(massCenter)
        }
    }

    func findMassCenter() -> SCNNode? {
        guard let rootNode = scnView.scene?.rootNode else { return nil }
        
        var minVector = SCNVector3Zero
        var maxVector = SCNVector3Zero
        rootNode.__getBoundingBoxMin(&minVector, max: &maxVector)
        
        let centerX = (minVector.x + maxVector.x) / 2
        let centerY = (minVector.y + maxVector.y) / 2
        let centerZ = (minVector.z + maxVector.z) / 2
        
        let massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(centerX, centerY, centerZ)
        
        return massCenter
    }
    
    func setupCamera(cameraNode: SCNNode){
        cameraNode.camera = SCNCamera()
        
        scnView.scene?.rootNode.addChildNode(cameraNode)
        let wall = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! == "Wall0"
            })[0]
        
        print("root/Node -> \(scnView.scene!.rootNode.worldOrientation)")
        var X: [Float] = [1000000.0, -1000000.0]
        var Z: [Float] = [1000000.0, -1000000.0]
        
        let massCenter = SCNNode()
        
        scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
            .forEach{
                
                let material = SCNMaterial()
                material.diffuse.contents = ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") ? UIColor.white : UIColor.black
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                if ($0.worldPosition.x < X[0]) {X[0] = $0.worldPosition.x}
                if ($0.worldPosition.x > X[1]) {X[1] = $0.worldPosition.x}
                if ($0.worldPosition.z < Z[0]) {Z[0] = $0.worldPosition.z}
                if ($0.worldPosition.z > Z[1]) {Z[1] = $0.worldPosition.z}
                print("\(String(describing: $0.name)), \($0.worldPosition)")
            }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        cameraNode.worldPosition = massCenter.worldPosition
        cameraNode.worldPosition.y = 10
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 20
        cameraNode.rotation.y = wall!.rotation.y
        cameraNode.rotation.w = wall!.rotation.w
        // Create directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        
        scnView.scene?.rootNode.addChildNode(massCenter)
        
        let vConstraint = SCNLookAtConstraint(target: massCenter)
        cameraNode.constraints = [vConstraint]
        directionalLight.constraints = [vConstraint]
        
    }
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        print("Change Color of Node: \(nodeName)")
        drawSceneObjects(borders: false)
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
            print("All nodes with prefix '__selected__' have been removed.")
        } else {
            print("No nodes with prefix '__selected__' found.")
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        print("Creazione di SCNView e aggiunta dei riconoscitori di gesti")
        
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

@available(iOS 17.0, *)
struct SCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewContainer()
    }
}


