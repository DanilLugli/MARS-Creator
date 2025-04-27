import SwiftUI
import SceneKit
import simd
import Accelerate

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
                    newMaterial.diffuse.contents = floor.getRoomByName(room.name)?.color
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
            // Definisce i tipi di nodi da considerare
            var targetPrefixes = ["Window", "Opening", "Door"]
            let furniturePrefixes = ["Table", "Storage"]

            if self.showFornitures {
                targetPrefixes.append(contentsOf: furniturePrefixes)
            }

            let matchingNodes = findNodesRecursively(in: room.sceneObjects!, matching: targetPrefixes)

            matchingNodes.forEach { node in
                let clonedNode = node.clone()
                clonedNode.name = "clone_" + (node.name ?? "Unnamed")
                clonedNode.scale = SCNVector3(1, 1, 1)

                if let originalGeometry = clonedNode.geometry {
                    let clonedGeometry = originalGeometry.copy() as! SCNGeometry
                    let material = SCNMaterial()
                    material.lightingModel = .physicallyBased

                    // Definizione del colore in base al tipo di nodo
                    if let nodeName = clonedNode.name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                        switch true {
                        case nodeName.hasPrefix("clone_open"):
                            material.diffuse.contents = UIColor.blue
                        case nodeName.hasPrefix("clone_door"):
                            material.diffuse.contents = UIColor.yellow
                        case nodeName.hasPrefix("clone_wind"):
                            material.diffuse.contents = UIColor.red
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
                let nodeName = node.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Senza nome"

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
        self.rotateRight()
    }

    func rotateCounterClockwise() {
        self.rotateLeft()
    }

    func moveUp(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomPositionDown(step: step)
    }

    func moveDown(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        // Per il movimento "down" chiamiamo moveRoomPositionUp, come nell'originale
        moveRoomPositionUp(step: step)
    }

    func moveLeft(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomPositionLeft(step: step)
    }

    func moveRight(continuous: Bool) {
        let step: CGFloat = continuous ? translationStepPressable : translationStep
        moveRoomPositionRight(step: step)
    }
    
   func findMaxAverageDistanceToCentroid(nodes: [SCNNode]) -> (node1: SCNNode, node2: SCNNode, node3: SCNNode, average: Float)? {
       guard nodes.count >= 3 else {
           print("Errore: Sono necessari almeno 3 nodi per formare un triangolo.")
           return nil
       }
       
       let points = nodes.simd
       var maxAverage: Float = 0
       var bestNodes: (SCNNode, SCNNode, SCNNode) = (nodes[0], nodes[1], nodes[2])
       
       // Considera tutte le combinazioni possibili di tre nodi
       for i in 0..<nodes.count {
           for j in (i+1)..<nodes.count {
               for k in (j+1)..<nodes.count {
                   let p0 = points[i]
                   let p1 = points[j]
                   let p2 = points[k]
                   let c = SCNViewAutoUpdatePositionRoomUtility.calculateCentroid(points: [p0, p1, p2])
                   
                   let currAverage = (distance(p0, c) + distance(p1, c) + distance(p2, c)) / 3
                   
                   if currAverage > maxAverage {
                       maxAverage = currAverage
                       bestNodes = (nodes[i], nodes[j], nodes[k])
                   }
               }
           }
       }
       
       return (bestNodes.0, bestNodes.1, bestNodes.2, maxAverage)
   }
    
    func autoPosition(continuous: Bool) {
        resetRoomPosition()
        
        guard let roomNode else {
            return
        }
        
        guard let floor else {
            return
        }
        
        let roomNodes = roomNode.childNodes
        guard let floorNodes = floor.sceneObjects else {
            return
        }
        
        let targetPrefixes = ["Window", "Opening", "Door"]
        
        let filteredRoomNodes = roomNodes.filter { node in targetPrefixes.contains { prefix in node.name?.contains(prefix) ?? false }}
        let filteredFloorNodes = floorNodes.filter { node in targetPrefixes.contains { prefix in node.name?.contains(prefix) ?? false }}
        
        print()
        print("----------ROOM----------")
        for (i, roomNode) in roomNodes.enumerated() {
            print("[\(i)] Node name: \(roomNode.name ?? "Null"))")
        }
        print()
        
        print()
        print("----------FLOOR----------")
        for (i, floorNode) in filteredFloorNodes.enumerated() {
            print("[\(i)] Node name: \(floorNode.name ?? "Null"))")
        }
        print()
        
//        DispatchQueue.global(qos: .userInitiated).async {
//            print(candidateNodes(for: roomNodes, in: floorNodes))
//        }
//        
//        return
//        
//        let (roomNode0, roomNode1, roomNode2, _) = findMaxAverageDistanceToCentroid(nodes: roomNodes)!
        
//        let roomNode0 = SCNNode()
//        roomNode0.simdWorldPosition = simd_float3(0, 0, 1)
//        let roomNode1 = SCNNode()
//        roomNode1.simdWorldPosition = simd_float3(1, 0, 1)
//        let roomNode2 = SCNNode()
//        roomNode2.simdWorldPosition = simd_float3(1, 0, 0)
//        
//        let floorNode0 = SCNNode()
//        floorNode0.simdWorldPosition = simd_float3(1, 0, 1)
//        
//        let floorNode1 = SCNNode()
//        floorNode1.simdWorldPosition = simd_float3(1, 0, 0)
//        
//        let floorNode2 = SCNNode()
//        floorNode2.simdWorldPosition = simd_float3(0, 0, 0)
        
        DispatchQueue.global(qos: .userInitiated).async {
//            let candidateFloorNodes = candidateNodes(for: filteredRoomNodes, in: filteredFloorNodes)
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print(filteredRoomNodes)
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print(candidateFloorNodes)
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
            let (rotationAngle, translation) = SCNViewAutoUpdatePositionRoomUtility.findBestAlignment(
                nodesA: roomNodes, // [roomNode0, roomNode1, roomNode2],
                nodesB: floorNodes, // [floorNode0, floorNode1, floorNode2],
                maxCombinations: 1000
            )
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print(rotationAngle)
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
//            print(translation)
//            print("GHJGJHGHJHGHGJHGJGHHGJGHJ")
            
            self.rotate(angle: rotationAngle)
            self.moveRoom(horizontal: CGFloat(translation.x), vertical: CGFloat(translation.z))
            
            // Costruisci matrice di rotazione + traslazione in world space
//            let cosTheta = cos(rotationAngle)
//            let sinTheta = sin(rotationAngle)
//
//            var transform = matrix_identity_float4x4
//            transform.columns.0 = simd_float4( cosTheta, 0, sinTheta, 0)
//            transform.columns.1 = simd_float4(       0, 1,      0, 0)
//            transform.columns.2 = simd_float4(-sinTheta, 0, cosTheta, 0)
//            transform.columns.3 = simd_float4(translation.x, 0, translation.z, 1)
//
//            // Converti in sistema locale del parentNode
//            if let parentTransform = roomNode.parent?.simdTransform {
//                let localTransform = simd_inverse(parentTransform) * transform
//                roomNode.simdTransform = localTransform
//            } else {
//                // Se non ha parent, sei già nello spazio globale
//                roomNode.simdTransform = transform
//            }
        }
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
        
        print("DEBUG: Room moved by (\(horizontal), \(vertical))")
    }
    
    // Le funzioni esistenti possono essere semplificate utilizzando moveRoom
    func moveRoomPositionDown(step: CGFloat) {
        moveRoom(horizontal: 0, vertical: -step)
    }

    func moveRoomPositionUp(step: CGFloat) {
        moveRoom(horizontal: 0, vertical: step)
    }

    func moveRoomPositionLeft(step: CGFloat) {
        moveRoom(horizontal: -step, vertical: 0)
    }

    func moveRoomPositionRight(step: CGFloat) {
        moveRoom(horizontal: step, vertical: 0)
    }
    
    func moveRoomPosition(by t: simd_float3) {
        guard let roomNode = roomNode else { return }
        
        // Trasla il nodo della stanza
        roomNode.worldPosition.x += t.x
        roomNode.worldPosition.y += t.y
        roomNode.worldPosition.z += t.z
        
        // Aggiorna la matrice di associazione
        floor?.associationMatrix[roomName!]?.translation[3][0] += t.x
        floor?.associationMatrix[roomName!]?.translation[3][1] += t.y
        floor?.associationMatrix[roomName!]?.translation[3][2] += t.z
    }
    
    func rotate(angle: Float) {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        print("DEBUG: Current eulerAngles.y before rotation: \(roomNode.eulerAngles.y)")
        
        // Crea la matrice di rotazione con l'angolo passato come parametro
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
        
        // Applica la rotazione al nodo
        roomNode.simdTransform = matrix_multiply(roomNode.simdTransform, rotationMatrix)
        
        // Aggiorna la matrice di associazione
        let previousMatrix = floor?.associationMatrix[roomName ?? ""]?.r_Y ?? matrix_identity_float4x4
        let updatedMatrix = matrix_multiply(previousMatrix, rotationMatrix)
        floor?.associationMatrix[roomName ?? ""]?.r_Y = updatedMatrix
        
        print("DEBUG: Applied rotation with angle: \(angle) radians")
    }
    
    func rotateRight() {
        rotate(angle: -rotationStep) // Rotazione a destra (orario)
    }
    
    func rotateLeft() {
        rotate(angle: rotationStep) // Rotazione a sinistra (antiorario)
    }
    
    // Funzione per ruotare con un angolo specifico
    func rotateToAngle(angle: Float) {
        // Calcola l'angolo desiderato
        guard let roomNode = roomNode else { return }
        
        // Ottieni l'angolo corrente
        let currentAngle = roomNode.eulerAngles.y
        
        // Calcola la differenza di angolo necessaria
        let angleDiff = angle - currentAngle
        
        // Applica la rotazione
        rotate(angle: angleDiff)
    }
    
    func resetRoomPosition() {
        guard let roomNode = roomNode else {
            print("DEBUG: No roomNode found!")
            return
        }
        
        moveRoom(horizontal: CGFloat(-roomNode.worldPosition.x), vertical: CGFloat(-roomNode.worldPosition.z))
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

struct SCNViewAutoUpdatePositionRoomUtility {
    // Lista di prefissi target con ordine di preferenza
    static let targetPrefixes = ["Door", "Opening", "Window"] //, "Table", "Storage"]
    
    // Funzione per calcolare il centroide di un array di punti
    static func calculateCentroid(points: [simd_float3]) -> simd_float3 {
        var sum = simd_float3(0, 0, 0)
        for point in points {
            sum += point
        }
        return sum / Float(points.count)
    }
    
    // Funzione per calcolare la rotazione attorno all'asse y e la traslazione x,z
    static func computeTransformation(from sourcePoints: [simd_float3], to targetPoints: [simd_float3]) -> (rotationAngle: Float, translation: simd_float3) {
        guard sourcePoints.count == targetPoints.count, sourcePoints.count >= 3 else {
            fatalError("Sono necessari almeno 3 punti corrispondenti")
        }
        
        // 1. Calcola i centroidi
        let sourceCentroid = calculateCentroid(points: sourcePoints)
        let targetCentroid = calculateCentroid(points: targetPoints)
        
        // 2. Sottrai i centroidi dai punti
        let centeredSourcePoints = sourcePoints.map { $0 - sourceCentroid }
        let centeredTargetPoints = targetPoints.map { $0 - targetCentroid }
        
        // 3. Trova l'angolo di rotazione ottimale attorno all'asse y
        var numerator: Float = 0
        var denominator: Float = 0
        
        for i in 0..<sourcePoints.count {
            let source = centeredSourcePoints[i]
            let target = centeredTargetPoints[i]
            
            // Per rotazione attorno all'asse y: x' = x*cos(θ) + z*sin(θ), z' = -x*sin(θ) + z*cos(θ)
            numerator += source.z * target.x - source.x * target.z
            denominator += source.x * target.x + source.z * target.z
        }
        
        let rotationAngle = atan2(numerator, denominator)
        
        // 4. Calcola la matrice di rotazione
        let cosTheta = cos(rotationAngle)
        let sinTheta = sin(rotationAngle)
        
        let rotationMatrix = simd_float3x3(
            simd_float3(cosTheta, 0, sinTheta),
            simd_float3(0, 1, 0),
            simd_float3(-sinTheta, 0, cosTheta)
        )
        
        // 5. Ruota i punti centrati e calcola la traslazione
        let rotatedSourcePoints = sourcePoints.map { rotationMatrix.transpose * $0 }
        
        // La traslazione è la differenza tra il centroide del target e il centroide del source ruotato
        let rotatedSourceCentroid = calculateCentroid(points: rotatedSourcePoints)
        let translation = targetCentroid - rotatedSourceCentroid
        
        return (rotationAngle, translation)
    }
    
    // Funzione per applicare la trasformazione a un punto
    static func transformPoint(point: simd_float3, rotationAngle: Float, translation: simd_float3) -> simd_float3 {
        let cosTheta = cos(rotationAngle)
        let sinTheta = sin(rotationAngle)
        
        // Matrice di rotazione attorno all'asse y
        let rotationMatrix = simd_float3x3(
            simd_float3(cosTheta, 0, sinTheta),
            simd_float3(0, 1, 0),
            simd_float3(-sinTheta, 0, cosTheta)
        )
        
        // Applica rotazione e poi traslazione
        let rotated = rotationMatrix.transpose * point
        return rotated + translation
    }
    
    // Funzione per calcolare l'errore di allineamento
    static func computeError(for A: [simd_float3], rotationAngle: Float, translation: simd_float3, comparedTo B: [simd_float3]) -> Float {
        precondition(A.count == B.count, "Input point sets must have the same number of points")
        
        return A.enumerated().reduce(0.0) { (totalError, element) in
            let transformedPoint = transformPoint(point: A[element.offset], rotationAngle: rotationAngle, translation: translation)
            let error = simd_length(transformedPoint - B[element.offset])
            print("A: \(A[element.offset])")
            print("transformedPoint: \(transformedPoint)")
            print("B: \(B[element.offset])")
            print()
            return totalError + error * error
        }
    }
    
    static func findBestAlignment(
        nodesA: [SCNNode],
        nodesB: [SCNNode],
        maxCombinations: Int
    ) -> (rotationAngle: Float, translation: simd_float3) {
        let filteredNodesA = nodesA.filter { node in targetPrefixes.contains { prefix in node.name?.contains(prefix) ?? false }}
        let filteredNodesB = nodesB.filter { node in targetPrefixes.contains { prefix in node.name?.contains(prefix) ?? false }}
        
        let triplets = findCompatibleTriplets(from: filteredNodesA, and: filteredNodesB, maxPairs: maxCombinations)
        
        var minError = Float(-1);
        var bestRotationAngle: Float = 0.0;
        var bestTranslation: simd_float3 = simd_float3(0, 0, 0);
        
        // Itera su tutte le combinazioni
        for (nodeSetA, nodeSetB) in triplets {
            let pointSetA = nodeSetA.simd;
            let pointSetB = nodeSetB.simd;
            
            let (rotationAngle, translation) = computeTransformation(from: pointSetA, to: pointSetB)
            
            // Calcola l'errore
            let error = computeError(for: pointSetA, rotationAngle: rotationAngle, translation: translation, comparedTo: pointSetB)
            
            if (error < minError || minError == Float(-1)) {
                minError = error
                
                bestRotationAngle = rotationAngle;
                bestTranslation = translation;
            }
            
            print("Error: \(error)")
            print("Min error: \(minError)")
            print()
            print("rotationAngle: \(rotationAngle) (\(rotationAngle * 180 / .pi)°)")
            print("translation: \(translation)")
            print()
        }
        
        return (bestRotationAngle, bestTranslation)
    }

    // Funzione helper per generare tutte le possibili triple da una lista di nodi
    static func generateTriplets(from nodes: [SCNNode]) -> [NodeTriplet] {
        var triplets: [NodeTriplet] = []
        
        let n = nodes.count
        // Utilizzo un approccio con indici per ottimizzazione
        for i in 0..<(n-2) {
            for j in (i+1)..<(n-1) {
                for k in (j+1)..<n {
                    triplets.append(NodeTriplet(nodes: [nodes[i], nodes[j], nodes[k]]))
                }
            }
        }
        
        return triplets
    }

    // Funzione principale per trovare le coppie di triple compatibili
    static func findCompatibleTriplets(from firstList: [SCNNode], and secondList: [SCNNode], maxPairs: Int = 1000) -> [([SCNNode], [SCNNode])] {
        // Controllo che ci siano abbastanza nodi
        guard firstList.count >= 3 && secondList.count >= 3 else {
            return []
        }
        
        // Genero tutte le possibili triple dalla prima lista
        let firstTriplets = generateTriplets(from: firstList)
        
        // Genero tutte le possibili triple dalla seconda lista
        let secondTriplets = generateTriplets(from: secondList)
        
        print("firstTriplets: \(firstTriplets.count)")
        print("secondTriplets: \(secondTriplets.count)")
        
        // Array per memorizzare i risultati (triplet1, triplet2, score)
        var compatibilityScores: [(NodeTriplet, NodeTriplet, Float)] = []
        
        // Limito il numero di triplet da confrontare per ottimizzazione
        let maxFirstTriplets = min(1000, firstTriplets.count)
        let sampledFirstTriplets = Array(firstTriplets.shuffled().prefix(maxFirstTriplets))
        
        // Limito il numero di triplet da confrontare per ottimizzazione
        let maxSecondTriplets = min(10000, secondTriplets.count)
        let sampledsecondTriplets = Array(secondTriplets.shuffled().prefix(maxSecondTriplets))
        
        // Calcolo i punteggi di compatibilità
        for triplet1 in sampledFirstTriplets {
            for triplet2 in sampledsecondTriplets {
                let score = triplet1.compatibilityScore(with: triplet2)
                compatibilityScores.append((triplet1, triplet2, score))
            }
        }
        
        // Ordino in base al punteggio (più basso = più compatibile)
        compatibilityScores.sort { $0.2 < $1.2 }
        
        // Prendo le migliori coppie
        let bestPairs = compatibilityScores.prefix(maxPairs)
        
        // Converto nel formato richiesto
        return bestPairs.map { ($0.0.nodes, $0.1.nodes) }
    }
}

struct NodeTriplet {
    let centroid: simd_float3
    let nodes: [SCNNode]
    let distanceMatrix: [[Float]]
    let relativeHeights: [Float]
    
    init(nodes: [SCNNode]) {
        guard nodes.count == 3 else {
            fatalError("Sono necessari 3 punti nodi")
        }
        
        let centroid = SCNViewAutoUpdatePositionRoomUtility.calculateCentroid(points: nodes.simd)
        self.nodes = nodes.sorted { distance($0.worldPosition.simd, centroid) < distance($1.worldPosition.simd, centroid) }
        self.centroid = centroid
        
        // Calcolo distanze
        self.distanceMatrix = NodeTriplet.generateDistanceMatrix(points: self.nodes.simd + [self.centroid])
        
        // Calcolo altezze relative
        let minY = self.nodes.map { $0.worldPosition.y }.min()!
        self.relativeHeights = self.nodes.map { $0.worldPosition.y - minY }
    }
    
    // Calcola quanto sono compatibili due triple di nodi
    func compatibilityScore(with other: NodeTriplet) -> Float {
        // Differenza tra le distanze dei punti
        let d01 = abs(self.distanceMatrix[0][1] - other.distanceMatrix[0][1])
        let d02 = abs(self.distanceMatrix[0][2] - other.distanceMatrix[0][2])
        let d12 = abs(self.distanceMatrix[1][2] - other.distanceMatrix[1][2])
        
        // Differenza tra le distanze dei punti con il centroide
        let d0c = abs(self.distanceMatrix[0][3] - other.distanceMatrix[0][3])
        let d1c = abs(self.distanceMatrix[1][3] - other.distanceMatrix[1][3])
        let d2c = abs(self.distanceMatrix[2][3] - other.distanceMatrix[2][3])
        
        // Differenze nelle altezze relative
        let h0 = abs(self.relativeHeights[0] - other.relativeHeights[0])
        let h1 = abs(self.relativeHeights[1] - other.relativeHeights[1])
        let h2 = abs(self.relativeHeights[2] - other.relativeHeights[2])
        
        // Pesi per i diversi fattori
        let pointDistanceWeight: Float = 1.0
        let centroidDistanceWeight: Float = 1.0
        let heightWeight: Float = 1.0
        
        // Score totale (più basso = più compatibile)
        return pointDistanceWeight * (d01 + d02 + d12) + centroidDistanceWeight * (d0c + d1c + d2c) + heightWeight * (h0 + h1 + h2)
    }
    
    private static func generateDistanceMatrix(points: [simd_float3]) -> [[Float]] {
        var distanceMatrix: [[Float]] = Array(
            repeating: Array(repeating: 0.0, count: points.count),
            count: points.count
        )
        
        for (i, row) in distanceMatrix.enumerated() {
            for (j, _) in row.enumerated() where j > i {
                distanceMatrix[i][j] = distance(points[i], points[j])
                distanceMatrix[j][i] = distance(points[j], points[i])
            }
        }
        
        return distanceMatrix
    }
}

func combinations<T>(of elements: [T], taking k: Int) -> [[T]] {
    guard k > 0 else { return [[]] }
    guard k <= elements.count else { return [] }

    if k == elements.count {
        return [elements]
    }

    if k == 1 {
        return elements.map { [$0] }
    }

    var result: [[T]] = []

    for (i, element) in elements.enumerated() {
        let remaining = Array(elements[(i + 1)...])
        let subcombinations = combinations(of: remaining, taking: k - 1)
        result += subcombinations.map { [element] + $0 }
    }

    return result
}


// Funzione per calcolare il centroide di un array di punti
func calculateCentroid(points: [simd_float3]) -> simd_float3 {
    var sum = simd_float3(0, 0, 0)
    for point in points {
        sum += point
    }
    return sum / Float(points.count)
}

func generateDistanceMatrix(points: [simd_float3]) -> [[Float]] {
    var distanceMatrix: [[Float]] = Array(
        repeating: Array(repeating: 0.0, count: points.count),
        count: points.count
    )
    
    for (i, row) in distanceMatrix.enumerated() {
        for (j, _) in row.enumerated() where j > i {
            distanceMatrix[i][j] = distance(points[i], points[j])
            distanceMatrix[j][i] = distance(points[j], points[i])
        }
    }
    
    return distanceMatrix
}

func mse(distMatrix1: [[Float]], distMatrix2: [[Float]], uncertainty: Float = 0.1) -> Float {
    guard distMatrix1.count > 0 && distMatrix1[0].count > 0 && distMatrix1.count == distMatrix1.count && distMatrix1[0].count == distMatrix1[0].count else {
        fatalError("Le due matrici devono avere le stesse dimensioni non nulle")
    }

    var mse: Float = 0.0
    
    for (i, row) in distMatrix1.enumerated() {
        for (j, _) in row.enumerated() where j > i {
            let d1 = distMatrix1[i][j]
            let d2 = distMatrix2[i][j]
            
            let diff = abs(d1 - d2)
            mse += diff < uncertainty ? 0 : pow(diff, 2)
        }
    }

    return mse
}

func candidateNodes(for roomNodes: [SCNNode], in floorNodes: [SCNNode]) -> [SCNNode] {
    let roomPoints = roomNodes.simd
    let floorPoints = Array(floorNodes.simd.shuffled().prefix(10))
    
    var size = roomPoints.count

    while size > 0 {
        print("Start roomCombinations")
        let roomCombinations = combinations(of: roomPoints, taking: size)
        print("End roomCombinations")
        print()
        
        print("Start floorCombinations")
        let floorCombinations = combinations(of: floorPoints, taking: size)
        print("End floorCombinations")
        print()
        
        for (i, roomCombination) in roomCombinations.enumerated() {
            let roomCombCentroid = calculateCentroid(points: roomCombination)
            let orderedRoomCombination = roomCombination.sorted { distance($0, roomCombCentroid) < distance($1, roomCombCentroid) }
            let roomCombDistMatrix = generateDistanceMatrix(points: orderedRoomCombination + [roomCombCentroid])
            
            for (j, floorCombination) in floorCombinations.enumerated() {
                let floorCombCentroid = calculateCentroid(points: floorCombination)
                let orderedFloorCombination = floorCombination.sorted { distance($0, floorCombCentroid) < distance($1, floorCombCentroid) }
                let floorCombDistMatrix = generateDistanceMatrix(points: orderedFloorCombination + [floorCombCentroid])
                let error = mse(distMatrix1: roomCombDistMatrix, distMatrix2: floorCombDistMatrix, uncertainty: 5.0)
                print("mse: \(error)")
                
                if (error == 0) {
                    print()
                    print("[Size: \(size)][\(i)] Room Combination: \(roomCombination)")
                    print("[Size: \(size)][\(j)] Floor Combination: \(floorCombination)")
                    print("mse: \(error)")
                    return floorNodes.filter { node in floorCombination.contains { point in point == node.worldPosition.simd } }
                }
            }
        }
        
        print()
        
        size /= 2
    }
    
    return []
}

extension SCNVector3 {
    var simd: simd_float3 {
        return simd_float3(x: self.x, y: self.y, z: self.z)
    }
}

extension Array where Element == SCNVector3 {
    var simd: [simd_float3] {
        return self.map { $0.simd }
    }
}

extension Array where Element == SCNNode {
    var simd: [simd_float3] {
        return self.map { $0.simdWorldPosition }
    }
}

extension Array {
    func permutations() -> [[Element]] {
        guard count > 0 else { return [[]] }
        
        return indices.flatMap { i -> [[Element]] in
            var rest = self
            let element = rest.remove(at: i)
            return rest.permutations().map { [element] + $0 }
        }
    }
    
    func combinations(taking k: Int) -> [[Element]] {
        guard k > 0 else { return [[]] }
        guard k <= self.count else { return [] }

        if k == self.count {
            return [self]
        }

        if k == 1 {
            return self.map { [$0] }
        }

        var result: [[Element]] = []

        for (i, element) in self.enumerated() {
            let remaining = Array(self[(i + 1)...])
            let subcombinations = remaining.combinations(taking: k - 1)
            result += subcombinations.map { [element] + $0 }
        }

        return result
    }
}
