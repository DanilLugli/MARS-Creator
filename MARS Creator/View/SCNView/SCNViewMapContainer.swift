import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RoomPositionMatrix] = []
    
    var scnView: SCNView = SCNView(frame: .zero)
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    
    var gestureCoordinator: SCNViewGestureCoordinator?
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
        print("CHECK APPLY ROOM POSITION MATRIX TO \(String(describing: node.name))\n")
        
        let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
        
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
        let coordinator = SCNViewGestureCoordinator(scnView: handler.scnView, cameraNode: handler.cameraNode)

        handler.gestureCoordinator = coordinator // 👈 Salvalo se necessario

        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePinch(_:)))
        pinch.delegate = coordinator
        handler.scnView.addGestureRecognizer(pinch)

        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePan(_:)))
        pan.delegate = coordinator
        handler.scnView.addGestureRecognizer(pan)

        let rotate = UIRotationGestureRecognizer(target: coordinator, action: #selector(coordinator.handleRotation(_:)))
        rotate.delegate = coordinator
        handler.scnView.addGestureRecognizer(rotate)

        handler.scnView.backgroundColor = .white
        return handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}

}

extension SCNVector3: @retroactive Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
