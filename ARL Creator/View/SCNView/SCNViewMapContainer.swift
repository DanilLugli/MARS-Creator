import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RoomPositionMatrix] = []
    
    var scnView: SCNView = SCNView(frame: .zero)
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    
    var roomNode: String = ""
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
   
    func showAllRooms(floor: Floor) {
        guard let scene = self.scnView.scene else { return }

        scene.rootNode.enumerateChildNodes { node, _ in
            node.isHidden = false
        }

        floor.rooms.forEach { room in
            if let roomNode = scene.rootNode.childNode(withName: room.name, recursively: true) {
                roomNode.isHidden = false
            }
        }
        
        debugNodeVisibility(scene: scene)
    }
    
    func debugNodeVisibility(scene: SCNScene) {
        scene.rootNode.enumerateChildNodes { node, _ in
            print("Node: \(node.name ?? "Unnamed"), isHidden: \(node.isHidden)")
        }
    }
    
    func showOnlyRoom(named roomName: String, in floor: Floor) {
        guard let scene = self.scnView.scene else { return }

        scene.rootNode.childNodes.forEach { node in
            node.isHidden = false
        }

        floor.rooms.forEach { room in
            if let roomNode = scene.rootNode.childNode(withName: room.name, recursively: true) {
                roomNode.isHidden = (room.name != roomName)
            }
        }

        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: setMassCenter(scnView: self.scnView, forNodeName: roomName))
    }

    func loadRoomsMaps(floor: Floor, rooms: [Room], nameRoom: String? = nil) {

        do {
            
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            
            scnView.scene = nil
            scnView.scene = try SCNScene(url: floorFileURL)
            
            for room in rooms {
                if doesMatrixExist(for: room.name, in: floor.associationMatrix) {
                    let roomMap = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                    
                    do {
                        let roomScene = try SCNScene(url: URL(fileURLWithPath: roomMap.path))
                        
                        func createSceneNode(from scene: SCNScene) -> SCNNode {
                            let containerNode = SCNNode()
                            containerNode.name = "SceneContainer"

                            if let floorNode = scene.rootNode.childNode(withName: "Floor0", recursively: true) {
                                let clonedFloorNode = floorNode.clone()
                                clonedFloorNode.name = "Floor0"
                                let material = SCNMaterial()
                                material.diffuse.contents = floor.getRoomByName(room.name)?.color
                                material.lightingModel = .constant
                                clonedFloorNode.geometry?.materials = [material]
                                containerNode.addChildNode(clonedFloorNode)
                            }
                            else {
                                print("DEBUG: Node 'Floor0' not found in the provided scene for room \(room.name).")
                            }
                            
                            let sphereNode = SCNNode()
                            sphereNode.name = "SceneCenterMarker"
                            
                            let sphereGeometry = SCNSphere(radius: 0)
                            let sphereMaterial = SCNMaterial()
                            sphereMaterial.emission.contents = UIColor.orange.withAlphaComponent(0)
                            sphereMaterial.diffuse.contents = UIColor.orange.withAlphaComponent(0)
                            sphereGeometry.materials = [sphereMaterial]
                            sphereNode.geometry = sphereGeometry
                            containerNode.addChildNode(sphereNode)
                            
                            if let markerNode = containerNode.childNode(withName: "SceneCenterMarker", recursively: true) {
                                let localMarkerPosition = markerNode.position // Posizione locale del puntino
                                containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
                            } else {
                                print("DEBUG: SceneCenterMarker not found in the container for room \(room.name), pivot not modified.")
                            }
                            
                            return containerNode
                        }
                        
                        let roomNode = createSceneNode(from: roomScene)
                        roomNode.name = room.name
                        self.roomNode = roomNode.name ?? "Error"
                        roomNode.scale = SCNVector3(1, 1, 1)
   
                        if let matrix = floor.associationMatrix[room.name] {
                            applyRotoTraslation(to: roomNode, with: matrix)
                            print("DEBUG: Applied roto-translation matrix for room \(room.name).")
                        } else {
                            print("DEBUG: No roto-translation matrix found for room \(room.name).")
                        }
                        roomNode.simdWorldPosition.y = 5

                        scnView.scene?.rootNode.addChildNode(roomNode)
                    } catch {
                        print("DEBUG: Error loading scene for room \(room.name) from URL \(roomMap.path): \(error)")
                    }
                } else {
                    print("DEBUG: Skipping room \(room.name) because no matrix exists in the association matrix.")
                }
            }
            
            drawSceneObjects(scnView: self.scnView, borders: false, nodeOrientation: false)
            setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: setMassCenter(scnView: self.scnView, forNodeName: nameRoom))
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    

    func zoomIn() { cameraNode.camera?.orthographicScale -= 0.5 }
    
    func zoomOut() { cameraNode.camera?.orthographicScale += 0.5 }
    
    func moveFloorMapUp() {
        guard cameraNode.camera != nil else {
            return
        }
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
    
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RoomPositionMatrix) {
        print(" ViewMap PRE\n")
        printMatrix(node.simdWorldTransform)
        let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
        print("CombinedMatrix\n")
        printMatrix(combinedMatrix)
        node.simdWorldTransform = combinedMatrix * node.simdWorldTransform
        print("POST\n")
        printMatrix(node.simdWorldTransform)

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
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        handler.scnView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        handler.scnView.addGestureRecognizer(panGesture)
        
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
                camera.orthographicScale = max(1.0, min(newScale, 200.0)) // Limita lo zoom tra 5x e 50x
                gesture.scale = 1
            }
        }
        
        // Gestione dello spostamento tramite pan
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: parent.handler.scnView)
            
            // Regola la posizione della camera in base alla direzione del pan
            parent.handler.cameraNode.position.x -= Float(translation.x) * 0.04 // Spostamento orizzontale
            parent.handler.cameraNode.position.z -= Float(translation.y) * 0.04 // Spostamento verticale
            
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
