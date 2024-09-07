
import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

struct SCNViewTransitionZoneContainer: UIViewRepresentable {
    
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
        
        // Posiziona la camera sopra il massCenter
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
        
        // Configura la camera per la vista ortografica dall'alto
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        
        // Ruota la camera per guardare verso il basso
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
        
        // Crea una luce direzionale (opzionale)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        // Imposta la camera come punto di vista
        scnView.pointOfView = cameraNode
        
        // Rimuovi il LookAtConstraint per evitare che la camera ruoti
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
    
    func drawContent(borders: Bool) {
        print(borders)
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Floor0" && n.name! !=  "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach{
                let material = SCNMaterial()
                if $0.name == "Floor0" {
                    material.diffuse.contents = UIColor.green
                } else {
                    material.diffuse.contents = UIColor.black
                    if ($0.name!.prefix(5) == "Floor") {material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)}
                    if ($0.name!.prefix(6) == "Transi") {
                        print("Disegno \($0.name)")
                        material.diffuse.contents = UIColor.red // Colore per il perimetro
                        material.fillMode = .lines  // Questo renderà solo il contorno (wireframe) del nodo
                    }
                    if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") {material.diffuse.contents = UIColor.green}
                    material.lightingModel = .physicallyBased
                    $0.geometry?.materials = [material]
                    
                    if borders {
                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                        $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                    }
                }
            }
    }
    
    func loadRoomMaps(room: Room, borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            print("PIPPo")
            addDoorNodesBasedOnExistingDoors(room: room)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    func loadFloorPlanimetry(borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    //    func drawOrigin(_ o: SCNVector3,_ color: UIColor, _ size: CGFloat, _ addY: Bool = false) {
    //
    //        let sphere = generateSphereNode(color, size)
    //        sphere.name = "Origin"
    //
    //        print("Origin Drawn")
    //        print(sphere.worldTransform)
    //
    //        sphere.simdWorldPosition = simd_float3(o.x, o.y, o.z)
    //
    //        print(sphere.worldTransform)
    //
    //        if let r = Model.shared.actualRoto{sphere.simdWorldTransform = simd_mul(sphere.simdWorldTransform, r.traslation)}
    //        sphere.worldPosition.y -= 1
    //        if addY {sphere.worldPosition.y += 1}
    //
    //        scnView.scene?.rootNode.addChildNode(sphere)
    //
    //    }
    
    func zoomIn() {cameraNode.camera?.orthographicScale -= 0.5}
    
    func zoomOut() {cameraNode.camera?.orthographicScale += 0.5}
    
    func moveMapUp() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso l'alto
        cameraNode.simdWorldPosition.z += 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso l'alto): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapDown() {
        
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        scnView.pointOfView = cameraNode
        
        cameraNode.simdWorldPosition.z -= 1.0
        
        print("Nuova posizione della camera (verso il basso): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapRight() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso l'alto
        cameraNode.simdWorldPosition.x += 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso l'alto): \(cameraNode.simdWorldPosition)")
    }
    
    func moveMapLeft() {
        
        // Controllo se il cameraNode ha una camera associata
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        
        // Imposta il cameraNode come punto di vista della scena
        scnView.pointOfView = cameraNode
        
        // Sposta la camera verso il basso
        cameraNode.simdWorldPosition.x -= 1.0
        
        // Log per debug
        print("Nuova posizione della camera (verso il basso): \(cameraNode.simdWorldPosition)")
    }
    
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes{
            if (n.worldPosition.x < X[0]) {X[0] = n.worldPosition.x}
            if (n.worldPosition.x > X[1]) {X[1] = n.worldPosition.x}
            if (n.worldPosition.z < Z[0]) {Z[0] = n.worldPosition.z}
            if (n.worldPosition.z > Z[1]) {Z[1] = n.worldPosition.z}
        }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
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
        drawContent(borders: false)
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
    
    func makeUIView(context: Context) -> SCNView {
        print("add a tap gesture recognizer")
        handler.scnView = scnView
        let tapGesture = UIGestureRecognizer(
            target: self,
            action: #selector(self.handler.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func addDoorNodesBasedOnExistingDoors(room: Room) {
        
        let doorNodes = scnView.scene?.rootNode.childNodes(passingTest: { node, _ in
            if let nodeName = node.name {
                return (nodeName.hasPrefix("Door") || nodeName.hasPrefix("Opening")) && !nodeName.hasSuffix("_grp")
            }
            return false
        }) ?? []
        
        for doorNode in doorNodes {
            
            let doorWidth = doorNode.width
            let doorHeight = doorNode.height
            var doorDepth = doorNode.length
            
            let depthExtension: CGFloat = 0.6
            doorDepth += depthExtension
            
            let newDoorGeometry = SCNBox(width: doorWidth, height: doorHeight, length: doorDepth, chamferRadius: 0.0)
            
            let newDoorNode = SCNNode(geometry: newDoorGeometry)
            
            newDoorNode.transform = doorNode.transform
            
            let doorDirection = doorNode.simdWorldFront
            let inwardTranslation = SIMD3<Float>(doorDirection * Float(doorDepth / 2))
            
            newDoorNode.simdPosition = doorNode.simdPosition - inwardTranslation
            
            let nodeName = doorNode.name != nil ? "TransitionZone_\(doorNode.name!)" : "TransitionZone_Door"
            
            newDoorNode.name = nodeName
            
            scnView.scene?.rootNode.addChildNode(newDoorNode)
            
            let updateName = newDoorNode.name!.replacingOccurrences(of: "TransitionZone_", with: "")
            
            if !room.transitionZones.contains(where: { $0.name == updateName }) {
                print("AGGIUNGO \(updateName)")
                let transitionZones = TransitionZone(name: updateName, connection: Connection(name: ""))
                room.addTransitionZone(transitionZone: transitionZones)
                
            } else {
                print("Una TransitionZone con il nome \(nodeName) esiste già.")
            }
            print("Nuova porta aggiunta alla scena con nome \(newDoorNode.name!).")
        }
    }
    
    class Coordinator: NSObject {
        var parent: SCNViewTransitionZoneContainer
        
        init(_ parent: SCNViewTransitionZoneContainer) {
            self.parent = parent
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = parent.cameraNode.camera else { return }
            let scale = gesture.scale
            camera.orthographicScale /= Double(scale)
            gesture.scale = 1
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.scnView)
            parent.cameraNode.position.x -= Float(translation.x) * 0.01
            parent.cameraNode.position.z += Float(translation.y) * 0.01
            gesture.setTranslation(.zero, in: parent.scnView)
        }
    }
}

func buttonAction(_ index: Int) {
    print("Button \(index) pressed")
    // Aggiungi qui le azioni che desideri eseguire quando un bottone viene premuto
}

class HandleTap: UIViewController {
    var scnView: SCNView?
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        print("handleTap")
        
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView!.hitTest(p, options: nil)
        if let tappedNode = hitResults.first?.node {
            print(tappedNode)
        }
    }
}

@available(iOS 17.0, *)
struct SCNViewTransitionZoneContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewTransitionZoneContainer()
    }
}


