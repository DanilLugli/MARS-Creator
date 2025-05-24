import SwiftUI
import SceneKit
import simd

class SCNViewUpdatePositionRoomHandler: ObservableObject, MoveObject {
    
    private let identityMatrix = matrix_identity_float4x4

    @Published var rotoTraslation: RoomPositionMatrix = RoomPositionMatrix(
        name: "",
        translation: matrix_identity_float4x4,
        r_Y: matrix_identity_float4x4
    )
    
    @MainActor
    @Published var showFornitures: Bool = false {
        didSet {
            toggleFornituresVisibility(show: showFornitures)
        }
    }
    
    @Published var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    @Published var floor: Floor?
    var roomName: String?
    
//    @Published var showFornitures: Bool = false // 🔥 Toggle per mobili

    var zoomStep: CGFloat = 0.1
    var translationStep: CGFloat = 0.02
    var translationStepPressable: CGFloat = 0.25
    var rotationStep: Float = .pi / 200
    
    private let color: UIColor = UIColor.green.withAlphaComponent(0.4)
    
    var roomNode: SCNNode?
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
    
    @MainActor
    func toggleFornituresVisibility(show: Bool) {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }

        let furniturePrefixes = ["table", "storage", "chair", "sofa", "shelf", "cabinet"]

        func findFurnitureNodes(in node: SCNNode) -> [SCNNode] {
            var foundNodes: [SCNNode] = []

            for child in node.childNodes {
                if let nodeName = child.name?.lowercased(),
                   furniturePrefixes.contains(where: { nodeName.contains($0) }) {
                    foundNodes.append(child)
                }
                foundNodes.append(contentsOf: findFurnitureNodes(in: child)) // Cerca ricorsivamente nei figli
            }
            return foundNodes
        }

        let furnitureNodes = findFurnitureNodes(in: roomNode)

        // Imposta la visibilità
        furnitureNodes.forEach { $0.isHidden = !show }
        
        print("DEBUG: \(show ? "Showing" : "Hiding") \(furnitureNodes.count) furniture nodes.")
    }
    
    @MainActor
    func loadRoomMapsPosition(floor: Floor, room: Room, fornitures: Bool) {
        
        self.floor = floor
        self.roomName = room.name
        self.showFornitures = fornitures
        
        loadFloorScene(for: floor, into: self.scnView)
        
        self.rotoTraslation = floor.associationMatrix[room.name] ?? RoomPositionMatrix(
            name: "",
            translation: floor.associationMatrix[room.name]?.translation ?? matrix_identity_float4x4,
            r_Y: floor.associationMatrix[room.name]?.r_Y ?? matrix_identity_float4x4
        )
        
        let roomScene = room.scene
        
        func createSceneNode(from scene: SCNScene) -> SCNNode {
            let containerNode = SCNNode()
            containerNode.name = "SceneContainer"
            
            scene.rootNode.enumerateHierarchy { node, _ in
                print("  - \(node.name ?? "Unnamed Node")")
            }

            if let floorNode = scene.rootNode.childNode(withName: "Floor0", recursively: true) {
                let clonedFloorNode = floorNode.clone()
                clonedFloorNode.name = "Floor0"

                if let originalGeometry = floorNode.geometry {
                    let clonedGeometry = originalGeometry.copy() as! SCNGeometry
                    let newMaterial = SCNMaterial()
                    newMaterial.diffuse.contents = floor.getRoomByName(room.name)?.color.withAlphaComponent(0.3)
//                    newMaterial.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
                    newMaterial.lightingModel = .physicallyBased
                    clonedGeometry.materials = [newMaterial]
                    clonedFloorNode.geometry = clonedGeometry
                }
                
                containerNode.addChildNode(clonedFloorNode)
            } else {
                print("DEBUG: 'Floor0' not found in the provided scene for room \(room.name).")
            }
            
            let sphereNode = SCNNode()
            sphereNode.name = "SceneCenterMarker"
            let sphereGeometry = SCNSphere(radius: 0)
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor.orange
            sphereGeometry.materials = [sphereMaterial]
            sphereNode.geometry = sphereGeometry
            containerNode.addChildNode(sphereNode)
            
            if let markerNode = containerNode.childNode(withName: "SceneCenterMarker", recursively: true) {
                let localMarkerPosition = markerNode.position
                containerNode.pivot = SCNMatrix4MakeTranslation(localMarkerPosition.x, localMarkerPosition.y, localMarkerPosition.z)
            } else {
                print("DEBUG: SceneCenterMarker not found in the container for room \(room.name), pivot not modified.")
            }

            var targetPrefixes = ["Window", "Door"]
            let furniturePrefixes = ["Table", "Storage"]

            if self.showFornitures {
                targetPrefixes.append(contentsOf: furniturePrefixes)
            }

            let matchingNodes = findNodesRecursively(in: room.sceneObjects!, matching: targetPrefixes)

            matchingNodes.forEach { node in
                let clonedNode = node.clone()
                clonedNode.name = "clone_" + (node.name ?? "Unnamed")
                clonedNode.scale = SCNVector3(1, 1, 1)

                if clonedNode.geometry != nil {
                    let material = SCNMaterial()
                    material.lightingModel = .physicallyBased

                    if let nodeName = clonedNode.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                        switch true {
//                        case nodeName.hasPrefix("clone_open"):
//                            material.diffuse.contents = UIColor.blue
                        case nodeName.hasPrefix("clone_door"):
                            material.diffuse.contents = UIColor.orange.withAlphaComponent(0.5)
                        case nodeName.hasPrefix("clone_wind"):
                            material.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
                        case nodeName.hasPrefix("clone_wall"):
                            material.diffuse.contents = UIColor.black
                            clonedNode.scale.z *= 0.3
                        default:
                            material.diffuse.contents = UIColor.black.withAlphaComponent(0.3)
                        }
                    }

                    clonedNode.geometry?.firstMaterial = material

                    if furniturePrefixes.contains(where: { clonedNode.name?.lowercased().contains($0.lowercased()) == true }) {
                        clonedNode.isHidden = !self.showFornitures
                    }

                    containerNode.addChildNode(clonedNode)

                } else {
                    print("DEBUG: Nodo \(node.name ?? "Unnamed Node") non ha geometria.")
                }
            }

            return containerNode
        }
        
        func findNodesRecursively(in nodes: [SCNNode], matching prefixes: [String]) -> [SCNNode] {
            var resultNodes: [SCNNode] = []
            var seenNodeNames = Set<String>()

            func search(in node: SCNNode) {
                if let name = node.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                    let prefixMatch = prefixes.contains(where: { name.hasPrefix($0.lowercased()) })
                    let hasGrpSuffix = name.hasSuffix("grp")
                    let alreadySeen = seenNodeNames.contains(name)

                    if prefixMatch && !hasGrpSuffix && !alreadySeen {
                        print("DEBUG: Nodo TROVATO -> \(name)")
                        resultNodes.append(node)
                        seenNodeNames.insert(name)
                    }
                }

                // Ricorsione sui figli
                for child in node.childNodes {
                    search(in: child)
                }
            }

            for node in nodes {
                search(in: node)
            }

            print("DEBUG: Totale nodi trovati -> \(resultNodes.count)")
            return resultNodes
        }

        let roomNode = createSceneNode(from: roomScene!)
        roomNode.name = room.name
        roomNode.scale = SCNVector3(1, 1, 1)
        
        if let existingNode = scnView.scene?.rootNode.childNode(withName: room.name, recursively: true) {
            existingNode.removeFromParentNode()
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
        
       
        self.roomNode = roomNode
        
        drawSceneObjects(scnView: self.scnView, borders: true, nodeOrientation: true)
        
        setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: setMassCenter(scnView: self.scnView, forNodeName: roomNode.name))
       // createAxesNode()
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
        rotateRoomRight()
    }

    func rotateCounterClockwise() {
        rotateRoomLeft()
    }

    func moveUp(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomDown(step: step)
    }

    func moveDown(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        // Per il movimento "down" chiamiamo moveRoomPositionUp, come nell'originale
        moveRoomUp(step: step)
    }

    func moveLeft(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomLeft(step: step)
    }

    func moveRight(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomRight(step: step)
    }
    
    /**
     * Calcola e applica automaticamente il posizionamento di un nodo stanza rispetto agli oggetti del pavimento.
     * - Returns: Un valore booleano che indica se il posizionamento è stato eseguito correttamente.
     */
    func applyAutoPositioning() async -> Bool {
        guard let roomNode else { return false }
        guard let floor else { return false }
        
        let roomNodes = roomNode.childNodes
        guard let floorNodes = floor.sceneObjects else { return false }
        
        // Nascondi il nodo stanza
        roomNode.isHidden = true
        
        // Salva la posizione iniziale del nodo stanza
        let initialPosition = roomNode.worldPosition
        
        // Sposta temporaneamente la stanza all'origine per facilitare il calcolo dell’allineamento
        moveRoom(horizontal: CGFloat(-initialPosition.x), vertical: CGFloat(-initialPosition.z))
        
        // Esegue il calcolo dell’allineamento in background con priorità utente
        let (rotationAngle, translation, error) = await Task.detached(priority: .userInitiated) {
            // Trova il miglior allineamento tra i nodi della stanza e gli oggetti del pavimento
            return AutoPositionUtility.findBestAlignment(
                from: roomNodes,
                to: floorNodes,
                clusterSize: 3,
                maxPairs: 1000
            )
        }.value
        
        // Se il calcolo ha restituito un errore negativo, ripristina la posizione iniziale e termina
        if error < 0 {
            moveRoom(horizontal: CGFloat(initialPosition.x), vertical: CGFloat(initialPosition.z))
            roomNode.isHidden = false
            return false
        }
        
        // Applica la rotazione trovata
        rotateRoom(angle: rotationAngle)
        
        // Applica la traslazione calcolata
        moveRoom(horizontal: CGFloat(translation.x), vertical: CGFloat(translation.z))
        
        // Mostra il nodo stanza
        roomNode.isHidden = false
        
        return true
    }
        
    /**
     * Sposta il roomNode secondo le coordinate specificate.
     * - Parameters:
     *   - horizontal: Quanto spostare il nodo sull'asse x (positivo = destra, negativo = sinistra)
     *   - vertical: Quanto spostare il nodo sull'asse z (positivo = su, negativo = giù)
     */
    func moveRoom(horizontal: CGFloat, vertical: CGFloat) {
        guard let roomNode = roomNode, let roomName = roomName else {
            print("DEBUG: No roomNode or roomName found!")
            return
        }
        
        // Aggiorna la posizione del nodo
        roomNode.worldPosition.x += Float(horizontal)
        roomNode.worldPosition.z += Float(vertical)
        
        // Aggiorna la matrice di associazione
        floor?.associationMatrix[roomName]?.translation[3][0] += Float(horizontal)
        floor?.associationMatrix[roomName]?.translation[3][2] += Float(vertical)
    }
    
    /**
     * Ruota la stanza di un angolo specificato attorno all'asse Y.
     * - Parameters:
     *   - angle: L'angolo di rotazione in radianti da applicare al nodo stanza.
     */
    func rotateRoom(angle: Float) {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        // Crea la matrice di rotazione con l'angolo passato come parametro
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
        
        // Applica la rotazione al nodo
        roomNode.simdTransform = matrix_multiply(roomNode.simdTransform, rotationMatrix)
        
        // Aggiorna la matrice di associazione
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
    }
    
    func moveRoomDown(step: CGFloat) {
        moveRoom(horizontal: 0, vertical: -step)
    }

    func moveRoomUp(step: CGFloat) {
        moveRoom(horizontal: 0, vertical: step)
    }

    func moveRoomLeft(step: CGFloat) {
        moveRoom(horizontal: -step, vertical: 0)
    }

    func moveRoomRight(step: CGFloat) {
        moveRoom(horizontal: step, vertical: 0)
    }
    
    func rotateRoomRight() {
        rotateRoom(angle: -rotationStep) // Rotazione a destra (orario)
    }
    
    func rotateRoomLeft() {
        rotateRoom(angle: rotationStep) // Rotazione a sinistra (antiorario)
    }
    
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let camera = cameraNode.camera else { return }
        if gesture.state == .changed {
            let newScale = camera.orthographicScale / Double(gesture.scale)
            camera.orthographicScale = max(1.0, min(newScale, 200.0)) // Limita lo zoom tra 5x e 50x
            gesture.scale = 1
        }
    }
    
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        cameraNode.position.x -= Float(translation.x) * 0.04 // Spostamento orizzontale
        cameraNode.position.z -= Float(translation.y) * 0.04 // Spostamento verticale
        gesture.setTranslation(.zero, in: scnView)
    }
    
    @MainActor
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RoomPositionMatrix) {
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
