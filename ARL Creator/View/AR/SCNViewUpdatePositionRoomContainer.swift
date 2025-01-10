import SwiftUI
import SceneKit

class SCNViewUpdatePositionRoomHandler: ObservableObject, MoveObject {
    
    private let identityMatrix = matrix_identity_float4x4
    @State private var isFaceIDSuccess = false

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
        
        for room in floor.rooms {
            scnView.scene?.rootNode.childNode(withName: room.name, recursively: true)?.removeFromParentNode()
        }
        
        self.floor = floor
        self.roomName = room.name
        
        let floorFileURL = floor.floorURL
            .appendingPathComponent("MapUsdz")
            .appendingPathComponent("\(floor.name).usdz")
        
        do{
            scnView.scene = try SCNScene(url: floorFileURL)
        }
        catch{
            print("Error loading scene from URL: \(error)")
        }
        
        
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
                floorNode.name = "Floor0"
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.green.withAlphaComponent(0.2)
                floorNode.geometry?.materials = [material]
                containerNode.addChildNode(floorNode)
            } else {
                print("Node 'Floor0' not found in the provided scene.")
            }
            
            let sphereNode = SCNNode()
            sphereNode.name = "SceneCenterMarker"
            sphereNode.position = SCNVector3(0, 0, 0)
            
            let sphereGeometry = SCNSphere(radius: 0.1) // Raggio piccolo per rappresentare il punto
            let sphereMaterial = SCNMaterial()
            sphereMaterial.emission.contents = UIColor.orange // Colore fluorescente
            sphereMaterial.diffuse.contents = UIColor.orange
            sphereGeometry.materials = [sphereMaterial]
            sphereNode.geometry = sphereGeometry
            containerNode.addChildNode(sphereNode)
            
            if let markerNode = containerNode.childNode(withName: "SceneCenterMarker", recursively: true) {
                let localMarkerPosition = markerNode.position // Posizione locale del puntino
                containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
                print("Pivot impostato su SceneCenterMarker")
            } else {
                print("SceneCenterMarker non trovato, pivot non modificato.")
            }
            
            return containerNode
        }
        
        let roomNode = createSceneNode(from: roomScene!)
        roomNode.name = room.name
        
        roomNode.simdWorldPosition = simd_float3(0,5,0)
        
        floor.associationMatrix[room.name].map {
            applyRotoTraslation(to: roomNode, with: $0)
        } ?? print("No RotoTraslationMatrix found for room: \(room.name)")
        
        scnView.scene?.rootNode.addChildNode(roomNode)
        self.roomNode = roomNode
        
        drawSceneObjects(scnView: self.scnView, borders: true)
        setMassCenter(scnView: self.scnView)
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
        
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
        
        // Debug: Stampa l'angolo attuale prima della rotazione
        print("DEBUG: Current eulerAngles.y before rotation (Right): \(roomNode.eulerAngles.y)")
        
        // Rotazione
        roomNode.eulerAngles.y -= rotationStep
        
        // Debug: Stampa l'angolo attuale dopo la rotazione
        print("DEBUG: Updated eulerAngles.y after rotation (Right): \(roomNode.eulerAngles.y)")
        
        // Applica la matrice di rotazione
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(rotationStep, 0, 1, 0))
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        
        // Debug: Stampa la matrice prima e dopo
        print("DEBUG: Previous r_Y matrix: \(previousMatrix)")
        print("DEBUG: Updated r_Y matrix: \(updatedMatrix)")
        
        // Salva la matrice aggiornata
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
    }
    
    

    func rotateLeft() {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        // Debug: Stampa l'angolo attuale prima della rotazione
        print("DEBUG: Current eulerAngles.y before rotation (Left): \(roomNode.eulerAngles.y)")
        
        // Rotazione
        roomNode.eulerAngles.y += rotationStep
        
        // Debug: Stampa l'angolo attuale dopo la rotazione
        print("DEBUG: Updated eulerAngles.y after rotation (Left): \(roomNode.eulerAngles.y)")
        
        // Applica la matrice di rotazione
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(-rotationStep, 0, 1, 0))
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        
        // Debug: Stampa la matrice prima e dopo
        print("DEBUG: Previous r_Y matrix: \(previousMatrix)")
        print("DEBUG: Updated r_Y matrix: \(updatedMatrix)")
        
        // Salva la matrice aggiornata
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
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
        
        let combinedMatrix = rotoTraslation.translation * rotoTraslation.r_Y
        node.simdWorldTransform = combinedMatrix * node.simdWorldTransform

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


struct FaceIDSuccessView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5)
                .foregroundColor(.green)
                .frame(width: 100, height: 100)

            Path { path in
                path.move(to: CGPoint(x: 35, y: 50))
                path.addLine(to: CGPoint(x: 45, y: 65))
                path.addLine(to: CGPoint(x: 70, y: 40))
            }
            .trim(from: 0, to: isAnimating ? 1 : 0)
            .stroke(Color.green, lineWidth: 5)
            .frame(width: 100, height: 100)
            .animation(.easeInOut(duration: 0.5), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
