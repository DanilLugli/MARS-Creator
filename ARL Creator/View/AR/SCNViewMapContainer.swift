import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RotoTraslationMatrix] = []
    
    var scnView: SCNView = SCNView(frame: .zero)
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {

        //self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
        //setCamera()
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

                scnView.scene?.rootNode.addChildNode(roomNode)

            }
            
            drawSceneObjects(scnView: self.scnView, borders: borders)
            setMassCenter(scnView: self.scnView)
            setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
//    func drawSceneObjects(borders: Bool) {
//
//        var drawnNodes = Set<String>()
//        
//        scnView.scene?
//            .rootNode
//            .childNodes(passingTest: { n, _ in
//                n.name != nil &&
//                n.name! != "Room" &&
//                n.name! != "Floor0" &&
//                n.name! != "Geom" &&
//                String(n.name!.suffix(4)) != "_grp" &&
//                n.name! != "__selected__"
//            })
//            .forEach {
//                let nodeName = $0.name
//                let material = SCNMaterial()
//                if nodeName == "Floor0" {
//                    material.diffuse.contents = UIColor.green
//                } else {
//                    material.diffuse.contents = UIColor.black
//                    if nodeName?.prefix(5) == "Floor" {
//                        material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
//                    }
//                    if nodeName!.prefix(6) == "Transi" {
//                        material.diffuse.contents = UIColor.white
//                    }
//                    if nodeName!.prefix(4) == "Door" {
//                        material.diffuse.contents = UIColor.white
//                    }
//                    if nodeName!.prefix(4) == "Open"{
//                        material.diffuse.contents = UIColor.systemGray5
//                    }
//                    if nodeName!.prefix(4) == "Tabl" {
//                        material.diffuse.contents = UIColor.brown
//                    }
//                    if nodeName!.prefix(4) == "Chai"{
//                        material.diffuse.contents = UIColor.brown.withAlphaComponent(0.4)
//                    }
//                    if nodeName!.prefix(4) == "Stor"{
//                        material.diffuse.contents = UIColor.systemGray
//                    }
//                    if nodeName!.prefix(4) == "Sofa"{
//                        material.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 0.6)
//                    }
//                    if nodeName!.prefix(4) == "Tele"{
//                        material.diffuse.contents = UIColor.orange
//                    }
//                    
//                    material.lightingModel = .physicallyBased
//                    $0.geometry?.materials = [material]
//                    
//                }
//                drawnNodes.insert(nodeName!)
//            }
//    }
    
    func zoomIn() { cameraNode.camera?.orthographicScale -= 0.5 }
    
    func zoomOut() { cameraNode.camera?.orthographicScale += 0.5 }
    
    func moveFloorMapUp() {
        guard cameraNode.camera != nil else {
            return
        }
        // Muove la fotocamera verso il basso nel piano x-z (per spostare la mappa verso l'alto)
        cameraNode.position.z -= 1.0
    }
    
    func moveFloorMapDown() {
        guard cameraNode.camera != nil else {
            return
        }
        // Muove la fotocamera verso l'alto nel piano x-z (per spostare la mappa verso il basso)
        cameraNode.position.z += 1.0
    }
    
    func moveFloorMapRight() {
        guard cameraNode.camera != nil else {
            return
        }
        // Muove la fotocamera verso sinistra nel piano x-z (per spostare la mappa verso destra)
        cameraNode.position.x -= 1.0
    }
    
    func moveFloorMapLeft() {
        guard cameraNode.camera != nil else {
            return
        }
        // Muove la fotocamera verso destra nel piano x-z (per spostare la mappa verso sinistra)
        cameraNode.position.x += 1.0
    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        print("APPLY TO NODE: \(node.name ?? "Unnamed Node")")
        print("Initial Transform:")
        //printSimdFloat4x4(node.simdWorldTransform)

        let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
        node.simdWorldTransform = combinedMatrix * node.simdWorldTransform

        print("Updated Transform:")
        //printSimdFloat4x4(node.simdWorldTransform)
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

extension SCNVector3: @retroactive Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
