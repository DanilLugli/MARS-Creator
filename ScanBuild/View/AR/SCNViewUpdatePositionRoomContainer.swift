import SwiftUI
import SceneKit

class SCNViewUpdatePositionRoomHandler: ObservableObject {
    
    private let identityMatrix = matrix_identity_float4x4
    
    
    // Variabile @Published con valore iniziale
    @Published var rotoTraslation: RotoTraslationMatrix = RotoTraslationMatrix(
        name: "",
        translation: matrix_identity_float4x4,
        r_Y: matrix_identity_float4x4
    )
    
    var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    var floor: Floor?
    var roomName: String?
   
    
    // Incremento di zoom
    var zoomStep: CGFloat = 0.1
    // Incremento di traslazione per ogni pressione del pulsante
    var translationStep: CGFloat = 0.2
    // Incremento dell'angolo di rotazione (in radianti)
    var rotationStep: Float = .pi / 60 // 11.25 gradi
    
    
    private let color: UIColor = UIColor.orange.withAlphaComponent(0.3)
    
    // Nodo per la stanza caricata
    var roomNode: SCNNode?
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
    }
    
    func loadRoomMapsPosition(floor: Floor, roomURL: URL, borders: Bool) {
        do {
            self.floor = floor
            self.roomName = roomURL.deletingPathExtension().lastPathComponent
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            scnView.scene = try SCNScene(url: floorFileURL)
            
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
            
            rotoTraslation = floor.associationMatrix[roomURL.deletingPathExtension().lastPathComponent] ?? RotoTraslationMatrix(
                name: "",
                translation: matrix_identity_float4x4,
                r_Y: matrix_identity_float4x4
            )
            
            
            print("\n\nProcessing room URL: \(roomURL)")
            let roomScene = try SCNScene(url: roomURL)
            
            // Trova il nodo chiamato "Floor0" all'interno della stanza
            if let loadedRoomNode = roomScene.rootNode.childNode(withName: "Floor0", recursively: true) {
                print("Found 'Floor0' node for room at: \(roomURL)")
                
                // Estrai il nome della stanza dal nome del file
                let roomName = roomURL.deletingPathExtension().lastPathComponent
                
                // Cerca la matrice di trasformazione per la stanza nel dizionario associationMatrix
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
                
                // Aggiungi il nodo della stanza alla scena principale
                scnView.scene?.rootNode.addChildNode(loadedRoomNode)
                
                // Memorizza il nodo della stanza per applicare trasformazioni successive
                self.roomNode = loadedRoomNode
            } else {
                print("Node 'Floor0' not found in scene: \(roomURL)")
            }
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    
    func moveRoomPositionUp() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.z += Float(translationStep)
        rotoTraslation.translation[3][2] += Float(translationStep)
    }
    
    func moveRoomPositionDown() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.z -= Float(translationStep)
        rotoTraslation.translation[3][2] -= Float(translationStep)
    }
    
    func moveRoomPositionRight() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.x += Float(translationStep)
        rotoTraslation.translation[3][0] += Float(translationStep)
        
    }
    
    func moveRoomPositionLeft() {
        guard let roomNode = roomNode else {
            print("No room node available for movement")
            return
        }
        roomNode.position.x -= Float(translationStep)
        rotoTraslation.translation[3][0] -= Float(translationStep)
    }
    
    // Funzioni di rotazione
    func rotateClockwise() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y -= rotationStep
        // Aggiorna la matrice di rotazione
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(-rotationStep, 0, 1, 0))
        rotoTraslation.r_Y = matrix_multiply(rotoTraslation.r_Y, rotationMatrix)
    }
    
    func rotateCounterClockwise() {
        guard let roomNode = roomNode else {
            print("No room node available for rotation")
            return
        }
        roomNode.eulerAngles.y += rotationStep
        let rotationMatrix = simd_float4x4(SCNMatrix4MakeRotation(rotationStep, 0, 1, 0))
        rotoTraslation.r_Y = matrix_multiply(rotoTraslation.r_Y, rotationMatrix)
    }

//    
//    func updatePositionTranslation() {
//        // Assicurati di avere sia il floor che il roomName
//        guard let floor = self.floor, let roomName = self.roomName else {
//            print("Floor or roomName is nil")
//            return
//        }
//        
//        // Seleziona il roomMatrix
//        if var roomMatrix = floor.associationMatrix[roomName] {
//            // Modifica il valore
//            roomMatrix.translation = rotoTraslation.translation
//            
//            // Aggiorna il valore nel dizionario
//            floor.associationMatrix[roomName] = roomMatrix
//            
//            // Stampa per debug
//            print("Updated translation matrix:")
//            print(floor.associationMatrix[roomName]?.translation)
//            print("Function executed successfully")
//        } else {
//            print("No roomMatrix found for room \(roomName)")
//        }
//        
//        do {
//            try self.floor?.updateTranslationMatrixInJSON(for: self.roomName ?? "", newTranslationMatrix:rotoTraslation.translation ,jsonURL: self.floor?.floorURL.appendingPathComponent("\(self.floor?.name ?? "defaultName").json") ?? URL(fileURLWithPath: ""))
//        } catch {
//            print("Errore: \(error.localizedDescription)")
//        }
//    }
//    
//    func updatePositionRY() {
//        // Assicurati di avere sia il floor che il roomName
//        guard let floor = self.floor, let roomName = self.roomName else {
//            print("Floor or roomName is nil")
//            return
//        }
//        
//        // Seleziona il roomMatrix
//        if var roomMatrix = floor.associationMatrix[roomName] {
//            // Modifica il valore
//            roomMatrix.r_Y = rotoTraslation.r_Y
//            
//            // Aggiorna il valore nel dizionario
//            floor.associationMatrix[roomName] = roomMatrix
//            
//            // Stampa per debug
//            print("Updated translation matrix:")
//            print(floor.associationMatrix[roomName]?.r_Y ?? "")
//            print("Function executed successfully")
//        } else {
//            print("No roomMatrix found for room \(roomName)")
//        }
//        
//        do{
//            try self.floor?.updateRYMatrixInJSON(for: self.roomName ?? "", newRYMatrix: rotoTraslation.r_Y ,jsonURL: self.floor?.floorURL.appendingPathComponent("\(self.floor?.name ?? "defaultName").json") ?? URL(fileURLWithPath: ""))
//            
//        }
//        catch{
//            print("Errore: \(error.localizedDescription)")
//        }
//        
//    }

    
//    func moveRoomPositionUp() {
//        guard let roomNode = roomNode else {
//            print("No room node available for movement")
//            return
//        }
//        roomNode.position.z += Float(translationStep)
//    }
//    
//    func moveRoomPositionDown() {
//        guard let roomNode = roomNode else {
//            print("No room node available for movement")
//            return
//        }
//        roomNode.position.z -= Float(translationStep)
//    }
//    
//    func moveRoomPositionRight() {
//        guard let roomNode = roomNode else {
//            print("No room node available for movement")
//            return
//        }
//        roomNode.position.x += Float(translationStep)
//    }
//    
//    func moveRoomPositionLeft() {
//        guard let roomNode = roomNode else {
//            print("No room node available for movement")
//            return
//        }
//        roomNode.position.x -= Float(translationStep)
//    }
//    
//    // Funzioni di rotazione
//    func rotateClockwise() {
//        guard let roomNode = roomNode else {
//            print("No room node available for rotation")
//            return
//        }
//        roomNode.eulerAngles.y -= rotationStep
//    }
//    
//    func rotateCounterClockwise() {
//        guard let roomNode = roomNode else {
//            print("No room node available for rotation")
//            return
//        }
//        roomNode.eulerAngles.y += rotationStep
//    }
    
    private func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        cameraNode.camera = SCNCamera()
        cameraNode.worldPosition = massCenter.worldPosition
        
        cameraNode.worldPosition.y = 10
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        let vConstraint = SCNLookAtConstraint(target: massCenter)
        cameraNode.constraints = [vConstraint]
        directionalLight.constraints = [vConstraint]
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
                if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") { material.diffuse.contents = UIColor.red }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
                if borders {
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
            }
    }
    
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        node.simdWorldTransform.columns.3 = rotoTraslation.translation.columns.3 + node.simdWorldTransform.columns.3
        
        let r_Y = simd_float3x3([
            simd_float3(rotoTraslation.r_Y.columns.0.x, rotoTraslation.r_Y.columns.0.y, rotoTraslation.r_Y.columns.0.z),
            simd_float3(rotoTraslation.r_Y.columns.1.x, rotoTraslation.r_Y.columns.1.y, rotoTraslation.r_Y.columns.1.z),
            simd_float3(rotoTraslation.r_Y.columns.2.x, rotoTraslation.r_Y.columns.2.y, rotoTraslation.r_Y.columns.2.z)
        ])
        
        var currentRotation = simd_float3x3([
            simd_float3(node.simdWorldTransform.columns.0.x, node.simdWorldTransform.columns.0.y, node.simdWorldTransform.columns.0.z),
            simd_float3(node.simdWorldTransform.columns.1.x, node.simdWorldTransform.columns.1.y, node.simdWorldTransform.columns.1.z),
            simd_float3(node.simdWorldTransform.columns.2.x, node.simdWorldTransform.columns.2.y, node.simdWorldTransform.columns.2.z)
        ])
        
        currentRotation = r_Y * currentRotation
        
        node.simdWorldTransform.columns.0 = simd_float4(currentRotation.columns.0, node.simdWorldTransform.columns.0.w)
        node.simdWorldTransform.columns.1 = simd_float4(currentRotation.columns.1, node.simdWorldTransform.columns.1.w)
        node.simdWorldTransform.columns.2 = simd_float4(currentRotation.columns.2, node.simdWorldTransform.columns.2.w)
    }
}

struct SCNViewUpdatePositionRoomContainer: UIViewRepresentable {
    typealias UIViewType = SCNView
    @ObservedObject var handler: SCNViewUpdatePositionRoomHandler
    
    init() {
        let scnView = SCNView(frame: .zero)
        let cameraNode = SCNNode()
        let massCenter = SCNNode()
        let origin = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        
        self.handler = SCNViewUpdatePositionRoomHandler(scnView: scnView, cameraNode: cameraNode, massCenter: massCenter)
    }
    
    func makeUIView(context: Context) -> SCNView {
        handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

@available(iOS 17.0, *)
struct SCNViewUpdatePositionRoomContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewUpdatePositionRoomContainer()
    }
}
