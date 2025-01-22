import SwiftUI
import SceneKit

class SCNViewUpdatePositionRoomHandler: ObservableObject, MoveObject {
    
    private let identityMatrix = matrix_identity_float4x4

    @Published var rotoTraslation: RotoTraslationMatrix = RotoTraslationMatrix(
        name: "",
        translation: matrix_identity_float4x4,
        r_Y: matrix_identity_float4x4
    )
    
    @Published var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    @Published var floor: Floor?
    var roomName: String?
    
    var zoomStep: CGFloat = 0.1
    var translationStep: CGFloat = 0.02
    var rotationStep: Float = .pi / 200
    
    private let color: UIColor = UIColor.green.withAlphaComponent(0.3)
    
    var roomNode: SCNNode?
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
    
    @MainActor
    func loadRoomMapsPosition(floor: Floor, room: Room, borders: Bool) {
//        for room in floor.rooms {
//            scnView.scene?.rootNode.childNode(withName: room.name, recursively: true)?.removeFromParentNode()
//        }
        
        self.floor = floor
        self.roomName = room.name
        
        loadFloorScene(for: floor, into: self.scnView)
        
        self.rotoTraslation = floor.associationMatrix[room.name] ?? RotoTraslationMatrix(
            name: "",
            translation: floor.associationMatrix[room.name]?.translation ?? matrix_identity_float4x4,
            r_Y: floor.associationMatrix[room.name]?.r_Y ?? matrix_identity_float4x4
        )
        
        let roomScene = room.scene
        
        func createSceneNode(from scene: SCNScene) -> SCNNode {
            let containerNode = SCNNode()
            containerNode.name = "SceneContainer"

            if let floorNode = scene.rootNode.childNode(withName: "Floor0", recursively: true) {
                let clonedFloorNode = floorNode.clone()
                clonedFloorNode.name = "Floor0"
                
                // Copia la geometria del nodo originale
                if let originalGeometry = floorNode.geometry {
                    let clonedGeometry = originalGeometry.copy() as! SCNGeometry
                    
                    // Crea un nuovo materiale per evitare di condividere quello esistente
                    let newMaterial = SCNMaterial()
                    newMaterial.diffuse.contents = floor.getRoomByName(room.name)?.color
                    clonedGeometry.materials = [newMaterial]
                    
                    // Assegna la nuova geometria al nodo clonato
                    clonedFloorNode.geometry = clonedGeometry
                }
                
                containerNode.addChildNode(clonedFloorNode)
            } else {
                print("DEBUG: Node 'Floor0' not found in the provided scene for room \(room.name).")
            }

            // Aggiungi un puntino centrale come marker
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
                let localMarkerPosition = markerNode.position
                containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
            } else {
                print("DEBUG: SceneCenterMarker not found in the container for room \(room.name), pivot not modified.")
            }
            
            let targetPrefixes = ["Table", "Storage", "Chair", "Door", "Opening"]
            let matchingNodes = scene.rootNode.childNodes.filter { node in
                targetPrefixes.contains(where: { prefix in node.name?.hasPrefix(prefix) == true })
            }

            matchingNodes.forEach { node in
                node.scale = SCNVector3(1, 1, 1)
                if let geometry = node.geometry {
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.black
                    geometry.materials = [material]
                } else {
                    print("DEBUG: Node \(node.name ?? "Unnamed Node") has no geometry.")
                }
                print("ADD")
                containerNode.addChildNode(node.clone())
            }

            return containerNode
        }

        
        let roomNode = createSceneNode(from: roomScene!)
        roomNode.name = room.name
        roomNode.scale = SCNVector3(1, 1, 1)
        
        if let existingNode = scnView.scene?.rootNode.childNode(withName: room.name, recursively: true) {
            existingNode.removeFromParentNode() // Rimuovi il nodo esistente
            print("DEBUG: Existing node '\(room.name)' removed from the scene.")
        }
        
        if let matrix = floor.associationMatrix[room.name] {
            
            applyRotoTraslation(to: roomNode, with: matrix)
            print("DEBUG: Applied roto-translation matrix for room \(room.name).")
        } else {
            print("DEBUG: No roto-translation matrix found for room \(room.name).")
        }
        roomNode.simdWorldPosition.y = 5

        debugNodeProperties(roomNode)
        
        scnView.scene?.rootNode.addChildNode(roomNode)
        print("Local transform: \(roomNode.simdTransform)")
        print("World transform: \(roomNode.worldTransform)")
        self.roomNode = roomNode
        
        drawSceneObjects(scnView: self.scnView, borders: true)
        setMassCenter(scnView: self.scnView)
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
        createAxesNode()
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

    
    func rotateClockwise() {
        self.rotateRight()
    }

    func rotateCounterClockwise() {
        
        self.rotateLeft()
    }

    func moveUp() {
        self.moveRoomPositionDown()
    }

    func moveDown() {
        self.moveRoomPositionUp()
        
    }

    func moveLeft() {
        self.moveRoomPositionLeft()
    }

    func moveRight() {
        self.moveRoomPositionRight()
    }

    func moveRoomPositionUp() {
        guard let roomNode = roomNode else {
            return
        }
        roomNode.worldPosition.z += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][2] += Float(translationStep)
    }

    func moveRoomPositionDown() {
        guard let roomNode = roomNode else {
            return
        }
        
        roomNode.worldPosition.z -= Float(translationStep)
        
        floor?.associationMatrix[roomName!]?.translation[3][2] -= Float(translationStep)
    }

    func moveRoomPositionRight() {
        guard let roomNode = roomNode else {
            return
        }
        roomNode.worldPosition.x += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] += Float(translationStep)
        print(floor?.associationMatrix[roomName!]?.translation[3][0] ?? 0)
    }

    func moveRoomPositionLeft() {
        guard let roomNode = roomNode else {
            return
        }
        roomNode.worldPosition.x -= Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] -= Float(translationStep)
    }

    func rotateRight() {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        // Debug: Stato corrente prima della rotazione
        print("DEBUG: Current eulerAngles.y before rotation (Right): \(roomNode.eulerAngles.y)")
        
        // Crea una matrice di rotazione per il passo definito
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(-rotationStep, 0, 1, 0)) // Rotazione a destra (orario)

        // Combina la matrice di trasformazione corrente con quella di rotazione
        roomNode.simdTransform = matrix_multiply(roomNode.simdTransform, rotationMatrix)
        
        // Aggiorna la matrice di rotazione associata (r_Y)
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
        
        // Debug: Stato dopo la rotazione
        print("DEBUG: Updated simdTransform matrix: \(roomNode.simdTransform)")
        print("DEBUG: Updated r_Y matrix: \(updatedMatrix)")
    }
    
    func rotateLeft() {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        // Debug: Stato corrente prima della rotazione
        print("DEBUG: Current eulerAngles.y before rotation (Left): \(roomNode.eulerAngles.y)")
        
        // Crea una matrice di rotazione per il passo definito
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(rotationStep, 0, 1, 0)) // Rotazione a sinistra (antiorario)
        
        // Combina la matrice di trasformazione corrente con quella di rotazione
        roomNode.simdTransform = matrix_multiply(roomNode.simdTransform, rotationMatrix)
        
        // Aggiorna la matrice di rotazione associata (r_Y)
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
        
        // Debug: Stato dopo la rotazione
        print("DEBUG: Updated simdTransform matrix: \(roomNode.simdTransform)")
        print("DEBUG: Updated r_Y matrix: \(updatedMatrix)")
    }
    
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = cameraNode.camera else { return }
        if gesture.state == .changed {
            let newScale = camera.orthographicScale / Double(gesture.scale)
            camera.orthographicScale = max(5.0, min(newScale, 50.0)) // Limita lo zoom tra 5x e 50x
            gesture.scale = 1
        }
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        cameraNode.position.x -= Float(translation.x) * 0.01 // Spostamento orizzontale
        cameraNode.position.z += Float(translation.y) * 0.01 // Spostamento verticale
        gesture.setTranslation(.zero, in: scnView)
    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        print("Manual Room Position PRE\n")
        printMatrix(node.simdWorldTransform)
        let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
        print("CombinedMatrix\n")
        printMatrix(combinedMatrix)
        node.simdWorldTransform = combinedMatrix * node.simdWorldTransform
        print("POST\n")
        printMatrix(node.simdWorldTransform)

        
    }
    
    func loadFloorScene(for floor: Floor, into scnView: SCNView) {
        let floorFileURL = floor.floorURL
            .appendingPathComponent("MapUsdz")
            .appendingPathComponent("\(floor.name).usdz")
        
        do {
            scnView.scene = try SCNScene(url: floorFileURL)
        } catch let error {
            print("Error loading scene from URL \(floorFileURL): \(error.localizedDescription)")
        }
    }
    
}

struct SCNViewUpdatePositionRoomContainer: UIViewRepresentable {
    typealias UIViewType = SCNView
    var handler: SCNViewUpdatePositionRoomHandler
    
    init() {
        let scnView = SCNView(frame: .zero)
        let cameraNode = SCNNode()
        let massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.handler = SCNViewUpdatePositionRoomHandler(scnView: scnView, cameraNode: cameraNode, massCenter: massCenter)
    }
    
    func makeUIView(context: Context) -> SCNView {
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        handler.scnView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        handler.scnView.addGestureRecognizer(panGesture)
        
        return handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SCNViewUpdatePositionRoomContainer
        
        init(_ parent: SCNViewUpdatePositionRoomContainer) {
            self.parent = parent
        }
        
        // Gestore del pinch (zoom)
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            parent.handler.handlePinch(gesture)
        }

        // Gestore del pan (spostamento)
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            parent.handler.handlePan(gesture)
        }
    }
}

@available(iOS 17.0, *)
struct SCNViewUpdatePositionRoomContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewUpdatePositionRoomContainer()
    }
}
