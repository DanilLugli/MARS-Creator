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

                if clonedNode.geometry != nil {
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
    
    func applyAutoPositioning() async -> Bool {
        guard let roomNode else { return false }
        guard let floor else { return false }
        
        let roomNodes = roomNode.childNodes
        guard let floorNodes = floor.sceneObjects else { return false }
        
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
            return false
        }
        
        // Applica la rotazione trovata
        rotate(angle: rotationAngle)
        
        // Applica la traslazione calcolata
        moveRoom(horizontal: CGFloat(translation.x), vertical: CGFloat(translation.z))
        
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
    
    func rotate(angle: Float) {
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

struct AutoPositionUtility {
    // Lista dei tipi di nodo da mantenere
    static let targetTypes = ["Door", "Opening", "Window"]
    
    static func findBestAlignment(
        from sourceNodes: [SCNNode],
        to targetNodes: [SCNNode],
        clusterSize: Int = 3,
        maxPairs: Int = 1000
    ) -> (rotationAngle: Float, translation: simd_float3, error: Float) {
        let filteredSourceNodes = filterNodesByType(nodes: sourceNodes)
        let filteredTargetNodes = filterNodesByType(nodes: targetNodes)
        
        let clusters = findCompatibleClusters(
            from: filteredSourceNodes,
            and: filteredTargetNodes,
            clusterSize: clusterSize,
            maxPairs: maxPairs
        )
        
        var minError = Float(-1);
        var bestRotationAngle: Float = 0.0;
        var bestTranslation: simd_float3 = simd_float3(0, 0, 0);
        
        // Itera su tutte le combinazioni
        for (sourceCluster, targetCluster, compatibilityError) in clusters {
            let (rotationAngle, translation) = computeTransformation(from: sourceCluster, to: targetCluster)
            
            // Calcola l'errore di trasformazione
            let transformationError = computeTransformationError(
                for: sourceCluster,
                rotationAngle: rotationAngle,
                translation: translation,
                comparedTo: targetCluster
            )
            
            // Calcola l'errore totale
            let error = compatibilityError + transformationError
            
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
        
        return (bestRotationAngle, bestTranslation, minError)
    }
    
    private static func filterNodesByType(nodes: [SCNNode]) -> [SCNNode] {
        return nodes.filter { node in targetTypes.contains { targetType in node.type == targetType }}
    }
    
    // Funzione principale per trovare le coppie di cluster compatibili
    private static func findCompatibleClusters(
        from nodes1: [SCNNode],
        and nodes2: [SCNNode],
        clusterSize: Int = 3,
        maxPairs: Int = 1000,
        maxNodes1: Int = 20,
        maxNodes2: Int = 40,
        maxClusters1: Int = 1000,
        maxClusters2: Int = 10000
    ) -> [(NodeCluster, NodeCluster, Float)] {
        // Controllo che ci siano abbastanza nodi
        guard
            nodes1.count >= clusterSize,
            nodes2.count >= clusterSize
        else {
            return []
        }
        
        // Limito il numero di nodi da combinare per ottimizzazione
        let sampledNodes1 = maxNodes1 >= nodes1.count ? nodes1 : Array(nodes1.shuffled().prefix(maxNodes1))
        
        // Limito il numero di nodi da combinare per ottimizzazione
        let sampledNodes2 = maxNodes2 >= nodes2.count ? nodes2 : Array(nodes2.shuffled().prefix(maxNodes2))
        
        // Genero tutti i possibili cluster dalla prima lista
        let clusters1 = sampledNodes1.combinations(taking: clusterSize).map { NodeCluster(nodes: $0) }
        
        // Genero tutti i possibili cluster dalla seconda lista
        let clusters2 = sampledNodes2.combinations(taking: clusterSize).map { NodeCluster(nodes: $0) }
        
        // Array per memorizzare i risultati (cluster1, cluster2, error)
        var compatibilityErrors: [(NodeCluster, NodeCluster, Float)] = []
        
        // Limito il numero di cluster da confrontare per ottimizzazione
        let sampledClusters1 = maxClusters1 >= clusters1.count ? clusters1 : Array(clusters1.shuffled().prefix(maxClusters1))
        
        // Limito il numero di cluster da confrontare per ottimizzazione
        let sampledClusters2 = maxClusters2 >= clusters2.count ? clusters2 : Array(clusters2.shuffled().prefix(maxClusters2))
        
        // Calcolo i punteggi di compatibilità
        for cluster1 in sampledClusters1 {
            for cluster2 in sampledClusters2 {
                let error = cluster1.computeCompatibilityError(with: cluster2)
                compatibilityErrors.append((cluster1, cluster2, error))
            }
        }
        
        // Ordino in base al punteggio (più basso = più compatibile)
        compatibilityErrors.sort { $0.2 < $1.2 }
        
        // Prendo le migliori coppie
        let bestPairs = Array(compatibilityErrors.prefix(maxPairs))
        
        return bestPairs
    }
    
    // Funzione per calcolare la rotazione attorno all'asse y e la traslazione x,z
    private static func computeTransformation(
        from sourceCluster: NodeCluster,
        to targetCluster: NodeCluster
    ) -> (rotationAngle: Float, translation: simd_float3) {
        guard sourceCluster.size == targetCluster.size, sourceCluster.size >= 3 else {
            fatalError("Sono necessari cluster di almeno 3 nodi")
        }
        
        // 1. Recupera punti e centroidi
        let sourcePoints = sourceCluster.points
        let targetPoints = targetCluster.points
        
        let sourceCentroid = sourceCluster.centroid
        let targetCentroid = targetCluster.centroid
        
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
        let rotatedSourceCentroid = rotatedSourcePoints.getCentroid()
        let translation = targetCentroid - rotatedSourceCentroid
        
        return (rotationAngle, translation)
    }
    
    // Funzione per calcolare l'errore di allineamento
    private static func computeTransformationError(
        for sourceCluster: NodeCluster,
        rotationAngle: Float,
        translation: simd_float3,
        comparedTo targetCluster: NodeCluster
    ) -> Float {
        guard sourceCluster.size == targetCluster.size else {
            fatalError("Clusters must have the same number of nodes")
        }
        
        let sourcePoints = sourceCluster.points
        let targetPoints = targetCluster.points
        
        return sourcePoints.enumerated().reduce(0.0) { (totalError, element) in
            let i = element.offset
            let transformedPoint = sourcePoints[i].transformXZ(rotationAngle: rotationAngle, translation: translation)
            let error = simd_length(transformedPoint - targetPoints[i])
            
            print("A: \(sourcePoints[i])")
            print("transformedPoint: \(transformedPoint)")
            print("B: \(targetPoints[i])")
            print()
            
            return totalError + pow(error, 2)
        }
    }
}

struct NodeCluster {
    let nodes: [SCNNode]
    let points: [simd_float3]
    let centroid: simd_float3
    let distanceMatrix: [[Float]]
    let relativeHeights: [Float]
    let dimensions: [(width: Float, height: Float, depth: Float)]
    let types: [String?]
    
    var size: Int {
        return self.nodes.count
    }
    
    init(nodes: [SCNNode]) {
        guard nodes.count >= 3 else {
            fatalError("Sono necessari almeno 3 nodi")
        }
        
        // Calcolo centroide
        let centroid = nodes.simdWorldPositions.getCentroid()
        
        // Ordinamento nodi
        let sortedNodes = nodes.sorted { distance($0.simdWorldPosition, centroid) < distance($1.simdWorldPosition, centroid) }
        
        // Calcolo punti
        let points = sortedNodes.simdWorldPositions
        
        // Calcolo distanze
        let distanceMatrix = (sortedNodes.simdWorldPositions + [centroid]).getDistanceMatrix()
        
        // Calcolo altezze relative
        let relativeHeights = sortedNodes.simdWorldPositions.getRelativeHeights()
        
        // Calcolo dimensioni
        let dimensions = sortedNodes.map { $0.boundingBoxDim }
        
        // Calcolo tipi
        let types = sortedNodes.map { $0.type }
        
        self.nodes = sortedNodes
        self.centroid = centroid
        self.points = points
        self.distanceMatrix = distanceMatrix
        self.relativeHeights = relativeHeights
        self.dimensions = dimensions
        self.types = types
    }
    
    func computeCompatibilityError(
        with other: NodeCluster,
        threshold: Float = 0.1,
        distanceWeight: Float = 1.0,
        relativeHeightWeight: Float = 1.0,
        dimensionWeight: Float = 1.0,
        typeMismatchWeight: Float = 1.0,
        typeDiversityWeight: Float = 1.0
    ) -> Float {
        let distanceMSE = self.computeDistanceMSE(with: other, threshold: threshold)
        let relativeHeightMSE = self.computeRelativeHeightMSE(with: other, threshold: threshold)
        let dimensionMSE = self.computeDimensionMSE(with: other, threshold: threshold)
        let typeMismatchMSE = self.computeTypeMismatchMSE(with: other, threshold: threshold)
        let typeDiversityMSE = self.computeTypeDiversityMSE(with: other, threshold: threshold)
        
        return (
            distanceWeight * distanceMSE +
            relativeHeightWeight * relativeHeightMSE +
            dimensionWeight * dimensionMSE +
            typeMismatchWeight * typeMismatchMSE +
            typeDiversityWeight * typeDiversityMSE
        )
    }
    
    func computeDistanceMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.distanceMatrix.count > 0,
            self.distanceMatrix[0].count > 0,
            self.distanceMatrix.count == other.distanceMatrix.count,
            self.distanceMatrix[0].count == other.distanceMatrix[0].count
        else {
            fatalError("The two distance matrices must have the same non-zero dimensions.")
        }

        var mse: Float = 0.0
        
        for (i, row) in self.distanceMatrix.enumerated() {
            for (j, _) in row.enumerated() where j > i {
                let d1 = self.distanceMatrix[i][j]
                let d2 = other.distanceMatrix[i][j]
                
                let diff = abs(d1 - d2)
                mse += diff < threshold ? 0 : pow(diff, 2)
            }
        }

        return mse
    }
    
    func computeRelativeHeightMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.relativeHeights.count > 0,
            self.relativeHeights.count == other.relativeHeights.count
        else {
            fatalError("The two relative height arrays must have the same non-zero dimension.")
        }

        var mse: Float = 0.0
        
        for (i, _) in self.relativeHeights.enumerated() {
            let h1 = self.relativeHeights[i]
            let h2 = other.relativeHeights[i]
            
            let diff = abs(h1 - h2)
            mse += diff < threshold ? 0 : pow(diff, 2)
        }

        return mse
    }
    
    func computeDimensionMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.dimensions.count > 0,
            self.dimensions.count == other.dimensions.count
        else {
            fatalError("The two dimension arrays must have the same non-zero dimension.")
        }

        var mse: Float = 0.0
        
        for (i, _) in self.dimensions.enumerated() {
            let (w1, h1, d1) = self.dimensions[i]
            let (w2, h2, d2) = other.dimensions[i]
            
            let wDiff = abs(w1 - w2)
            mse += wDiff < threshold ? 0 : pow(wDiff, 2)
            
            let hDiff = abs(h1 - h2)
            mse += hDiff < threshold ? 0 : pow(hDiff, 2)
            
            let dDiff = abs(d1 - d2)
            mse += dDiff < threshold ? 0 : pow(dDiff, 2)
        }

        return mse
    }
    
    func computeTypeMismatchMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.types.count > 0,
            self.types.count == other.types.count
        else {
            fatalError("The two type arrays must have the same non-zero dimension.")
        }
        
        var totalError: Float = 0.0
        
        for (i, _) in self.types.enumerated() {
            let selfType = self.types[i] ?? ""
            let otherType = other.types[i] ?? ""
            
            // Calcola un errore binario: 0 se i tipi sono uguali, 1 se sono diversi
            let typeError: Float = (selfType == otherType) ? 0.0 : 1.0
            
            totalError += typeError
        }
        
        // Calcola la media degli errori
        let mse = self.size > 0 ? totalError / Float(self.size) : 1.0
        
        // Applica la soglia, se necessario
        return mse < threshold ? 0.0 : mse
    }
    
    func computeTypeDiversityMSE(with other: NodeCluster, threshold: Float = 0.1) -> Float {
        guard
            self.types.count > 0,
            self.types.count == other.types.count
        else {
            fatalError("The two type arrays must have the same non-zero dimension.")
        }
        
        // Raccoglie tutti i tipi unici nei due cluster
        let selfTypes = Set<String?>(self.types)
        let otherTypes = Set<String?>(other.types)
        
        // Calcola l'unione dei tipi unici tra i due cluster
        let unionTypes = selfTypes.union(otherTypes)
        
        // Se non ci sono tipi, restituisci un valore neutro
        if unionTypes.isEmpty {
            return 0.0
        }
        
        // Calcola quanti tipi diversi ci sono in totale tra i due cluster
        let totalUniqueTypes = Float(unionTypes.count)
        
        // Calcola il punteggio di diversità normalizzato (0-1)
        // Più alto è il valore, maggiore è la diversità
        let diversityScore = totalUniqueTypes / max(Float(selfTypes.count + otherTypes.count), 1.0)
        
        // Invertiamo il punteggio per trasformarlo in un "errore"
        // 1.0 - diversityScore fa sì che alta diversità = basso errore
        let mse = 1.0 - diversityScore
        
        // Applica la soglia, se necessario
        return mse < threshold ? 0.0 : mse
    }
}

extension SCNNode {
    var type: String? {
        guard let name = self.name else {
            return nil
        }
        
        let pattern = "(?:^clone_)+|\\d+$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(name.startIndex..<name.endIndex, in: name)
        return regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: "")
    }
    
    var boundingBoxDim: (width: Float, height: Float, depth: Float) {
        // Ottieni il boundingBox del nodo
        let (min, max) = self.boundingBox
        
        // Calcola la differenza tra i valori max e min per ottenere la dimensione
        let width = max.x - min.x
        let height = max.y - min.y
        let depth = max.z - min.z
        
        return (width, height, depth)
    }
}

extension simd_float3 {
    
    // Funzione per applicare la trasformazione a un punto
    func transformXZ(rotationAngle: Float = 0, translation: simd_float3 = simd_float3(0, 0, 0)) -> simd_float3 {
        let cosTheta = cos(rotationAngle)
        let sinTheta = sin(rotationAngle)
        
        // Matrice di rotazione attorno all'asse y
        let rotationMatrix = simd_float3x3(
            simd_float3(cosTheta, 0, sinTheta),
            simd_float3(0, 1, 0),
            simd_float3(-sinTheta, 0, cosTheta)
        )
        
        // Applica rotazione e poi traslazione
        let rotated = rotationMatrix.transpose * self
        return rotated + translation
    }
}

extension Array where Element == SCNNode {
    var simdWorldPositions: [simd_float3] {
        return self.map { $0.simdWorldPosition }
    }
}

extension Array where Element == simd_float3 {
    
    // Funzione per calcolare il centroide di un array di punti
    func getCentroid() -> simd_float3 {
        var sum = simd_float3(0, 0, 0)
        for point in self {
            sum += point
        }
        return sum / Float(self.count)
    }
    
    // Metodo per calcolare la matrice delle distanze
    func getDistanceMatrix() -> [[Float]] {
        var distanceMatrix: [[Float]] = Array<[Float]>(
            repeating: Array<Float>(repeating: 0.0, count: self.count),
            count: self.count
        )
        
        for (i, row) in distanceMatrix.enumerated() {
            for (j, _) in row.enumerated() where j > i {
                distanceMatrix[i][j] = simd.distance(self[i], self[j])
                distanceMatrix[j][i] = distanceMatrix[i][j]
            }
        }
        
        return distanceMatrix
    }
    
    // Metodo per calcolare le altezze relative
    func getRelativeHeights() -> [Float] {
        let minY = self.map { $0.y }.min()!
        return self.map { $0.y - minY }
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
