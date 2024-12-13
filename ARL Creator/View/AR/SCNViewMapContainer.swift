import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RotoTraslationMatrix] = []
    
    var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
        setCamera()
    }
    
    @MainActor
    func loadRoomsMaps(floor: Floor, rooms: [Room], borders: Bool) {
        do {
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            
            scnView.scene = nil
            scnView.scene = try SCNScene(url: floorFileURL)

            for room in rooms {
                
                let roomMap = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                
                let roomScene = try SCNScene(url: URL(fileURLWithPath: roomMap.path))
                
                func createSceneNode(from scene: SCNScene) -> SCNNode {
                    // Crea un nodo contenitore
                    let containerNode = SCNNode()
                    containerNode.name = "SceneContainer"
                    
                    // Cerca il nodo `Floor0`
                    if let floorNode = scene.rootNode.childNode(withName: "Floor0", recursively: true) {
                        floorNode.name = "Floor0"
                        let material = SCNMaterial()
                        material.diffuse.contents = floor.getRoomByName(room.name)?.color
                        floorNode.geometry?.materials = [material]
                        containerNode.addChildNode(floorNode)
                        print("Pino")
                    } else {
                        print("Node 'Floor0' not found in the provided scene.")
                    }
                    
                    // Aggiungi una sfera di colore arancione fluorescente per rappresentare il punto centrale
                    let sphereNode = SCNNode()
                    sphereNode.name = "SceneCenterMarker"
                    sphereNode.position = SCNVector3(0, 0, 0) // Centro locale del containerNode
                    
                    let sphereGeometry = SCNSphere(radius: 0.1) // Raggio piccolo per rappresentare il punto
                    let sphereMaterial = SCNMaterial()
                    sphereMaterial.emission.contents = UIColor.orange // Colore fluorescente
                    sphereMaterial.diffuse.contents = UIColor.orange
                    sphereGeometry.materials = [sphereMaterial]
                    sphereNode.geometry = sphereGeometry
                    containerNode.addChildNode(sphereNode)
                    
                    // Imposta il pivot del nodo contenitore sul puntino arancione
                    if let markerNode = containerNode.childNode(withName: "SceneCenterMarker", recursively: true) {
                        let localMarkerPosition = markerNode.position // Posizione locale del puntino
                        containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
                        print("Pivot impostato su SceneCenterMarker")
                    } else {
                        print("SceneCenterMarker non trovato, pivot non modificato.")
                    }
                    
                    return containerNode
                }
                
                var roomNode = createSceneNode(from: roomScene)
                roomNode.name = room.name
                
                roomNode.simdWorldPosition = simd_float3(0,5,0)
                
                if let rotoTraslationMatrix = floor.associationMatrix[room.name] {
                    applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
                } else {
                    print("No RotoTraslationMatrix found for room: \(room.name)")
                }
                
//                let material = SCNMaterial()
//                material.diffuse.contents = floor.getRoomByName(room.name)?.color
//                roomNode.geometry?.materials = [material]
                
                scnView.scene?.rootNode.addChildNode(roomNode)
                
//                if let roomNode = roomScene.rootNode.childNode(withName: "Floor0", recursively: true) {
//                    
//                    let roomName = room.name
//                    roomNode.name = room.name
//                    roomNode.worldPosition = SCNVector3(0.0,0.0,0.0)
//                    
//                    if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
//                        applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
//                    } else {
//                        print("No RotoTraslationMatrix found for room: \(roomName)")
//                    }
//                    
//                    //roomNode.name = roomName
//                    
//                    let material = SCNMaterial()
//                    material.diffuse.contents = floor.getRoomByName(roomName)?.color
//                    roomNode.geometry?.materials = [material]
//                    
//                    scnView.scene?.rootNode.addChildNode(roomNode)
//                } else {
//                    print("Node 'Floor0' not found in scene: \(roomMap)")
//                }
            }
            
            drawSceneObjects(borders: borders)
            setMassCenter()
            setCamera()
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    func printAllNodes(in node: SCNNode?, indent: String = "") {
        guard let node = node else { return }
        
        print("\(indent)Node: \(node.name ?? "Unnamed"), Position: \(node.position)")
        
        for child in node.childNodes {
            printAllNodes(in: child, indent: indent + "  ")
        }
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
    
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes {
            if (n.worldPosition.x < X[0]) { X[0] = n.worldPosition.x }
            if (n.worldPosition.x > X[1]) { X[1] = n.worldPosition.x }
            if (n.worldPosition.z < Z[0]) { Z[0] = n.worldPosition.z }
            if (n.worldPosition.z > Z[1]) { Z[1] = n.worldPosition.z }
        }
        massCenter.worldPosition = SCNVector3((X[0] + X[1]) / 2, 0, (Z[0] + Z[1]) / 2)
        return massCenter
    }
    
    func drawContent(borders: Bool) {
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in
                n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Geom" &&
                !n.name!.hasPrefix("Floor") &&
                String(n.name!.suffix(4)) != "_grp" &&
                n.name! != "__selected__"
            })
            .forEach {
                let material = SCNMaterial()
                
                if $0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open" {
                    material.diffuse.contents = UIColor.white
                } else {
                    material.diffuse.contents = UIColor.black
                }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
                if borders {
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
            }
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in n.name?.hasPrefix("Floor") ?? false
            })
            .forEach { node in
                node.removeFromParentNode()
            }
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
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        drawContent(borders: false)
        if let _node = scnView.scene?.rootNode.childNodes(passingTest: { n,_ in n.name != nil && n.name! == nodeName }).first {
            let copy = _node.copy() as! SCNNode
            copy.name = "__selected__"
            let material = SCNMaterial()
            let transparentColor = color.withAlphaComponent(0.3)
            material.diffuse.contents = transparentColor
            material.lightingModel = .physicallyBased
            copy.geometry?.materials = [material]
            scnView.scene?.rootNode.addChildNode(copy)
        }
    }
    
    func zoomIn() { cameraNode.camera?.orthographicScale -= 0.5
        print("IN")}
    
    func zoomOut() { cameraNode.camera?.orthographicScale += 0.5
        print("OUT")}
    
    func moveFloorMapUp() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso il basso nel piano x-z (per spostare la mappa verso l'alto)
        cameraNode.position.z -= 1.0
    }
    
    func moveFloorMapDown() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso l'alto nel piano x-z (per spostare la mappa verso il basso)
        cameraNode.position.z += 1.0
    }
    
    func moveFloorMapRight() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso sinistra nel piano x-z (per spostare la mappa verso destra)
        cameraNode.position.x -= 1.0
    }
    
    func moveFloorMapLeft() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso destra nel piano x-z (per spostare la mappa verso sinistra)
        cameraNode.position.x += 1.0
    }
    
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.camera = SCNCamera()
        
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
        
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0) // Vista dall'alto
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        cameraNode.constraints = []
    }
    
    func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    //    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
    //
    //        print("NODE: ")
    //        print(node)
    //        print("\n")
    //        print(node.simdWorldTransform.columns.3)
    //        print("\n")
    //        print(rotoTraslation.translation)
    //        print("\n\n\n\n\n")
    //        node.simdWorldTransform.columns.3 = node.simdWorldTransform.columns.3 * rotoTraslation.translation
    //
    //        let r_Y = simd_float3x3([
    //            simd_float3(rotoTraslation.r_Y.columns.0.x, rotoTraslation.r_Y.columns.0.y, rotoTraslation.r_Y.columns.0.z),
    //            simd_float3(rotoTraslation.r_Y.columns.1.x, rotoTraslation.r_Y.columns.1.y, rotoTraslation.r_Y.columns.1.z),
    //            simd_float3(rotoTraslation.r_Y.columns.2.x, rotoTraslation.r_Y.columns.2.y, rotoTraslation.r_Y.columns.2.z),
    //        ])
    //
    //        var rot = simd_float3x3([
    //            simd_float3(node.simdWorldTransform.columns.0.x, node.simdWorldTransform.columns.0.y, node.simdWorldTransform.columns.0.z),
    //            simd_float3(node.simdWorldTransform.columns.1.x, node.simdWorldTransform.columns.1.y, node.simdWorldTransform.columns.1.z),
    //            simd_float3(node.simdWorldTransform.columns.2.x, node.simdWorldTransform.columns.2.y, node.simdWorldTransform.columns.2.z),
    //        ])
    //
    //        rot = r_Y * rot
    //
    //        node.simdWorldTransform.columns.0 = simd_float4(
    //            rot.columns.0.x,
    //            rot.columns.0.y,
    //            rot.columns.0.z,
    //            node.simdWorldTransform.columns.0.w
    //        )
    //        node.simdWorldTransform.columns.1 = simd_float4(
    //            rot.columns.1.x,
    //            rot.columns.1.y,
    //            rot.columns.1.z,
    //            node.simdWorldTransform.columns.1.w
    //        )
    //        node.simdWorldTransform.columns.2 = simd_float4(
    //            rot.columns.2.x,
    //            rot.columns.2.y,
    //            rot.columns.2.z,
    //            node.simdWorldTransform.columns.2.w
    //        )
    //    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        
        let translationVector = simd_float3(
            rotoTraslation.translation.columns.3.x,
            rotoTraslation.translation.columns.3.y,
            rotoTraslation.translation.columns.3.z
        )
        node.simdWorldPosition = node.simdWorldPosition + translationVector
        
        let rotationMatrix = rotoTraslation.r_Y
        
        let rotationQuaternion = simd_quatf(rotationMatrix)
        
        node.simdWorldOrientation = rotationQuaternion * node.simdWorldOrientation
        
    }
}

struct SCNViewMapContainer: UIViewRepresentable {
    typealias UIViewType = SCNView
    
    @ObservedObject var handler: SCNViewMapHandler
    
    init() {
        let scnView = SCNView(frame: .zero)
        let cameraNode = SCNNode()
        let massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        
        self.handler = SCNViewMapHandler(scnView: scnView, cameraNode: cameraNode, massCenter: massCenter)
    }
    
    func makeUIView(context: Context) -> SCNView {
        
        // Zoom
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        handler.scnView.addGestureRecognizer(pinchGesture)
        
        // Move
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        handler.scnView.addGestureRecognizer(panGesture)
        
        // Background Color
        handler.scnView.backgroundColor = UIColor.white
        
        return handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: SCNViewMapContainer
        
        init(_ parent: SCNViewMapContainer) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = parent.handler.cameraNode.camera else { return }
            
            if gesture.state == .changed {
                let newScale = camera.orthographicScale / Double(gesture.scale)
                camera.orthographicScale = max(5.0, min(newScale, 50.0)) // Limita lo zoom tra 5x e 50x
                gesture.scale = 1
            }
        }
        
        // Gestione dello spostamento tramite pan
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.handler.scnView)
            
            // Regola la posizione della camera in base alla direzione del pan
            parent.handler.cameraNode.position.x -= Float(translation.x) * 0.01 // Spostamento orizzontale
            parent.handler.cameraNode.position.z += Float(translation.y) * 0.01 // Spostamento verticale
            
            // Resetta la traduzione dopo ogni movimento
            gesture.setTranslation(.zero, in: parent.handler.scnView)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

@available(iOS 17.0, *)
struct SCNViewMapContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewMapContainer()
    }
}

extension SCNVector3: Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
