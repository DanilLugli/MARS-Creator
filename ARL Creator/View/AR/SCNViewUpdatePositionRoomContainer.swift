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
   
    
    // Incremento di zoom
    var zoomStep: CGFloat = 0.1
    // Incremento di traslazione per ogni pressione del pulsante
    var translationStep: CGFloat = 0.1
    // Incremento dell'angolo di rotazione (in radianti)
    var rotationStep: Float = .pi / 100 // 11.25 gradi
    
    
    private let color: UIColor = UIColor.green.withAlphaComponent(0.3)
    
    // Nodo per la stanza caricata
    var roomNode: SCNNode?
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
    
    
    @MainActor func loadRoomMapsPosition(floor: Floor, roomURL: URL, borders: Bool) {
        do {
            self.floor = floor
            self.roomName = roomURL.deletingPathExtension().lastPathComponent
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            scnView.scene = try SCNScene(url: floorFileURL)
            
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
            
            self.rotoTraslation = floor.associationMatrix[roomURL.deletingPathExtension().lastPathComponent] ?? RotoTraslationMatrix(
                name: "",
                translation: floor.associationMatrix[roomURL.deletingPathExtension().lastPathComponent]?.translation ?? matrix_identity_float4x4,
                r_Y: floor.associationMatrix[roomURL.deletingPathExtension().lastPathComponent]?.r_Y ?? matrix_identity_float4x4
            )
            
            print(self.rotoTraslation)
            print("\n\nProcessing room URL: \(roomURL)")
            let roomScene = try SCNScene(url: roomURL)
            
            // Trova il nodo chiamato "Floor0" all'interno della stanza
            if let loadedRoomNode = roomScene.rootNode.childNode(withName: "Floor0", recursively: true) {
                print("Found 'Floor0' node for room at: \(roomURL)")
                

                let roomName = roomURL.deletingPathExtension().lastPathComponent
                loadedRoomNode.worldPosition = SCNVector3(0,0,0)

                if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
                    print("Applying transformation for room: \(roomName)")
                    print("Translation matrix: \(rotoTraslationMatrix.translation)")
                    print("Rotation matrix (r_Y): \(rotoTraslationMatrix.r_Y)")
                    print("BEFORE POSITION: \nNode: \(loadedRoomNode.name ?? "Unnamed"), Position: \(loadedRoomNode.position)")

                    applyRotoTraslation(to: loadedRoomNode, with: rotoTraslationMatrix)
                    
                    print("AFTER POSITION: \nNode: \(loadedRoomNode.name ?? "Unnamed"), Position: \(loadedRoomNode.position)")
                    
                } else {
                    print("No RotoTraslationMatrix found for room: \(roomName)")
                }
                
                // Imposta il nome del nodo in base al nome del file della stanza
                loadedRoomNode.name = roomName
                print("RoomNode aggiunto: \(loadedRoomNode)")
                
                // Aggiungi un materiale per colorare il nodo
                let material = SCNMaterial()
                material.diffuse.contents = color
                loadedRoomNode.geometry?.materials = [material]

                scnView.scene?.rootNode.addChildNode(loadedRoomNode)
                
                self.roomNode = loadedRoomNode
            } else {
                print("Node 'Floor0' not found in scene: \(roomURL)")
            }
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    

    func normalizeNodeOrientationPreservingScale(_ node: SCNNode) {
        // Salva la scala originale
        let originalScale = node.scale
        
        // Reset della trasformazione (posizione e rotazione)
        node.transform = SCNMatrix4Identity
        
        // Ripristina la scala originale
        node.scale = originalScale
    }
    
    func rotateClockwise() {
        self.rotateRight()
    }

    func rotateCounterClockwise() {
        self.rotateLeft()
    }

    func moveUp() {
        self.moveRoomPositionUp()
    }

    func moveDown() {
        self.moveRoomPositionDown()
    }

    func moveLeft() {
        self.moveRoomPositionLeft()
    }

    func moveRight() {
        self.moveRoomPositionRight()
    }

    func moveRoomPositionUp() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.z += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][2] += Float(translationStep)
    }

    func moveRoomPositionDown() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.z -= Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][2] -= Float(translationStep)
    }

    func moveRoomPositionRight() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.x += Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] += Float(translationStep)
        print(floor?.associationMatrix[roomName!]?.translation[3][0] ?? 0)
    }

    func moveRoomPositionLeft() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.x -= Float(translationStep)
        floor?.associationMatrix[roomName!]?.translation[3][0] -= Float(translationStep)
    }

    func rotateRight() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y -= rotationStep

        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(-rotationStep, 0, 1, 0))
        floor?.associationMatrix[roomName ?? ""]?.r_Y = matrix_multiply(floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4, rotationMatrix)
    }

    func rotateLeft() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y += rotationStep
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(rotationStep, 0, 1, 0))
        floor?.associationMatrix[roomName ?? ""]?.r_Y = matrix_multiply(floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4, rotationMatrix)
        print("rotateCounterClockwise: \(String(describing: floor?.associationMatrix[roomName ?? ""]?.r_Y) )")
    }
    
    func setCamera() {
            scnView.scene?.rootNode.addChildNode(cameraNode)
            cameraNode.camera = SCNCamera()
            cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
            cameraNode.camera?.usesOrthographicProjection = true
            cameraNode.camera?.orthographicScale = 10
            cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
            
            let directionalLight = SCNNode()
            directionalLight.light = SCNLight()
            directionalLight.light!.type = .ambient
            directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
            cameraNode.addChildNode(directionalLight)
            
            scnView.pointOfView = cameraNode
            cameraNode.constraints = []
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
    
    private func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: {
            n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
        }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    private func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes {
            if n.worldPosition.x < X[0] { X[0] = n.worldPosition.x }
            if n.worldPosition.x > X[1] { X[1] = n.worldPosition.x }
            if n.worldPosition.z < Z[0] { Z[0] = n.worldPosition.z }
            if n.worldPosition.z > Z[1] { Z[1] = n.worldPosition.z }
        }
        massCenter.worldPosition = SCNVector3((X[0] + X[1]) / 2, 0, (Z[0] + Z[1]) / 2)
        return massCenter
    }
    
    private func drawContent(borders: Bool) {
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach{
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                if ($0.name!.prefix(5) == "Floor") { material.diffuse.contents = UIColor.white.withAlphaComponent(0.2) }
                if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") { material.diffuse.contents = UIColor.white }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
                if borders {
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
            }
    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        
        let translationVector = simd_float3(
            rotoTraslation.translation.columns.3.x,
            rotoTraslation.translation.columns.3.y,
            rotoTraslation.translation.columns.3.z
        )
        node.simdPosition = node.simdPosition + translationVector
        
        let rotationMatrix = rotoTraslation.r_Y
        
        let rotationQuaternion = simd_quatf(rotationMatrix)
        
        node.simdOrientation = rotationQuaternion * node.simdOrientation
        
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
