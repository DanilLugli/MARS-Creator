import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RotoTraslationMatrix] = []
    
    var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode = SCNNode()
    var origin: SCNNode = SCNNode()
    
    private var colorIndex = 0
    private let colors: [UIColor] = [
        UIColor.blue.withAlphaComponent(0.3),
        UIColor.yellow.withAlphaComponent(0.4),
        UIColor.green.withAlphaComponent(0.3),
        UIColor.red.withAlphaComponent(0.3),
        UIColor.orange.withAlphaComponent(0.3),
        UIColor.purple.withAlphaComponent(0.3),
        UIColor.brown.withAlphaComponent(0.3)
    ]
    
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
        self.origin.simdWorldTransform = simd_float4x4([1.0,0,0,0], [0,1.0,0,0], [0,0,1.0,0], [0,0,0,1.0])
        setCamera()
    }
    
    func loadRoomMaps(floor: Floor, roomURLs: [URL], borders: Bool) {
        do {
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz")
                .appendingPathComponent("\(floor.name).usdz")
            scnView.scene = try SCNScene(url: floorFileURL)
            
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
            
            // Itera attraverso ogni stanza (roomURL)
            for roomURL in roomURLs {
                print("\n\nProcessing room URL: \(roomURL)")
                let roomScene = try SCNScene(url: roomURL)
                
                // Trova il nodo chiamato "Floor0" all'interno della stanza
                if let roomNode = roomScene.rootNode.childNode(withName: "Floor0", recursively: true) {
                    print("Found 'Floor0' node for room at: \(roomURL)")
                    
                    // Estrai il nome della stanza dal nome del file
                    let roomName = roomURL.deletingPathExtension().lastPathComponent
                    
                    // Cerca la matrice di trasformazione per la stanza nel dizionario associationMatrix
                    if let rotoTraslationMatrix = floor.associationMatrix[roomName] {
                        print("Applying transformation for room: \(roomName)")
                        print("Translation matrix: \(rotoTraslationMatrix.translation)")
                        print("Rotation matrix (r_Y): \(rotoTraslationMatrix.r_Y)")
                        print("BEFORE POSITION: \nNode: \(roomNode.name ?? "Unnamed"), Position: \(roomNode.position)")
                        
                        applyRotoTraslation(to: roomNode, with: rotoTraslationMatrix)
                        
                        print("AFTER POSITION: \nNode: \(roomNode.name ?? "Unnamed"), Position: \(roomNode.position)")
                        
                    } else {
                        print("No RotoTraslationMatrix found for room: \(roomName)")
                    }
                    
                    // Imposta il nome del nodo in base al nome del file della stanza
                    roomNode.name = roomName
                    print("RoomNode aggiunto: \(roomNode)")
                    
                    // Aggiungi un materiale per colorare il nodo
                    let material = SCNMaterial()
                    material.diffuse.contents = colorForRoom(named: roomName) // Ottieni il colore per la stanza
                    roomNode.geometry?.materials = [material]
                    
                    // Aggiungi il nodo della stanza alla scena principale
                    scnView.scene?.rootNode.addChildNode(roomNode)
                } else {
                    print("Node 'Floor0' not found in scene: \(roomURL)")
                }
            }
            
            // Dopo aver aggiunto i nodi, stampa tutti i nodi della scena
            printAllNodes(in: scnView.scene?.rootNode)
            
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    
    func colorForRoom(named roomName: String) -> UIColor {
        let color = colors[colorIndex]
        colorIndex = (colorIndex + 1) % colors.count
        return color
    }
    
    
    func printAllNodes(in node: SCNNode?, indent: String = "") {
        guard let node = node else { return }
        
        // Stampa il nodo corrente con l'indentazione
        print("\(indent)Node: \(node.name ?? "Unnamed"), Position: \(node.position)")
        
        // Ricorsivamente stampa tutti i nodi figli
        for child in node.childNodes {
            printAllNodes(in: child, indent: indent + "  ")
        }
    }
    
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes {
            if (n.worldPosition.x < X[0]) { X[0] = n.worldPosition.x }
            if (n.worldPosition.x > X[1]) { X[1] = n.worldPosition.x }
            if (n.worldPosition.z < Z[0]) { Z[0] = n.worldPosition.z }
            if (n.worldPosition.z > Z[1]) { Z[1] = n.worldPosition.z }
        }
        massCenter.worldPosition = SCNVector3((X[0] + X[1]) / 2, 0, (Z[0] + Z[1]) / 2)
        return massCenter
    }
    
    func drawContent(borders: Bool) {
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in
                // Filtra i nodi che non devono essere esclusi
                n.name != nil && n.name! != "Room" && n.name! != "Geom" && !n.name!.hasPrefix("Floor") && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach {
                let material = SCNMaterial()
                // Applica i materiali solo ai nodi rimanenti
                if $0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open" {
                    material.diffuse.contents = UIColor.red
                } else {
                    material.diffuse.contents = UIColor.black
                }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]

                // Applica le modifiche di scala se richiesto
                if borders {
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
            }

        // Rimuovi tutti i nodi con prefisso "Floor"
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in n.name?.hasPrefix("Floor") ?? false
            })
            .forEach { node in
                node.removeFromParentNode()
            }
    }
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        drawContent(borders: false)
        if let _node = scnView.scene?.rootNode.childNodes(passingTest: { n,_ in n.name != nil && n.name! == nodeName }).first {
            let copy = _node.copy() as! SCNNode
            copy.name = "__selected__"
            let material = SCNMaterial()
            let transparentColor = color.withAlphaComponent(0.3)
            material.diffuse.contents = transparentColor
            material.lightingModel = .physicallyBased
            copy.geometry?.materials = [material]
            scnView.scene?.rootNode.addChildNode(copy)
        }
    }
    
    func zoomIn() { cameraNode.camera?.orthographicScale -= 0.5 }
    
    func zoomOut() { cameraNode.camera?.orthographicScale += 0.5 }
    
    func moveFloorMapUp() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso il basso nel piano x-z (per spostare la mappa verso l'alto)
        cameraNode.position.z -= 1.0
    }

    func moveFloorMapDown() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso l'alto nel piano x-z (per spostare la mappa verso il basso)
        cameraNode.position.z += 1.0
    }

    func moveFloorMapRight() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso sinistra nel piano x-z (per spostare la mappa verso destra)
        cameraNode.position.x -= 1.0
    }

    func moveFloorMapLeft() {
        guard cameraNode.camera != nil else {
            print("Errore: cameraNode non ha una camera associata.")
            return
        }
        // Muove la fotocamera verso destra nel piano x-z (per spostare la mappa verso sinistra)
        cameraNode.position.x += 1.0
    }
    
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.camera = SCNCamera()
        
        // Posiziona la camera sopra il massCenter
        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
        
        // Configura la camera per la vista ortografica dall'alto
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        
        // Ruota la camera per guardare verso il basso
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
        
        // Crea una luce direzionale (opzionale)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        // Imposta la camera come punto di vista
        scnView.pointOfView = cameraNode
        
        // Rimuovi il LookAtConstraint per evitare che la camera ruoti
        cameraNode.constraints = []
    }
    
    func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    
    //    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
    //
    //        print("NODE: ")
    //        print(node)
    //        print("\n")
    //        print(node.simdWorldTransform.columns.3)
    //        print("\n")
    //        print(rotoTraslation.translation)
    //        print("\n\n\n\n\n")
    //        node.simdWorldTransform.columns.3 = node.simdWorldTransform.columns.3 * rotoTraslation.translation
    //
    //        let r_Y = simd_float3x3([
    //            simd_float3(rotoTraslation.r_Y.columns.0.x, rotoTraslation.r_Y.columns.0.y, rotoTraslation.r_Y.columns.0.z),
    //            simd_float3(rotoTraslation.r_Y.columns.1.x, rotoTraslation.r_Y.columns.1.y, rotoTraslation.r_Y.columns.1.z),
    //            simd_float3(rotoTraslation.r_Y.columns.2.x, rotoTraslation.r_Y.columns.2.y, rotoTraslation.r_Y.columns.2.z),
    //        ])
    //
    //        var rot = simd_float3x3([
    //            simd_float3(node.simdWorldTransform.columns.0.x, node.simdWorldTransform.columns.0.y, node.simdWorldTransform.columns.0.z),
    //            simd_float3(node.simdWorldTransform.columns.1.x, node.simdWorldTransform.columns.1.y, node.simdWorldTransform.columns.1.z),
    //            simd_float3(node.simdWorldTransform.columns.2.x, node.simdWorldTransform.columns.2.y, node.simdWorldTransform.columns.2.z),
    //        ])
    //
    //        rot = r_Y * rot
    //
    //        node.simdWorldTransform.columns.0 = simd_float4(
    //            rot.columns.0.x,
    //            rot.columns.0.y,
    //            rot.columns.0.z,
    //            node.simdWorldTransform.columns.0.w
    //        )
    //        node.simdWorldTransform.columns.1 = simd_float4(
    //            rot.columns.1.x,
    //            rot.columns.1.y,
    //            rot.columns.1.z,
    //            node.simdWorldTransform.columns.1.w
    //        )
    //        node.simdWorldTransform.columns.2 = simd_float4(
    //            rot.columns.2.x,
    //            rot.columns.2.y,
    //            rot.columns.2.z,
    //            node.simdWorldTransform.columns.2.w
    //        )
    //    }
    
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        
        print("NODE: \(node.name ?? "Unnamed Node")\n")
        print("Current Node Position: \(node.simdWorldTransform.columns.3)\n")
        print("RotoTraslation Translation Matrix: \(rotoTraslation.translation)\n")
        
        print("AAA: \(rotoTraslation.translation.columns.3)")
        
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
        
        print("Updated Node Position: \(node.simdWorldTransform.columns.3)")
    }
}

struct SCNViewMapContainer: UIViewRepresentable {
    typealias UIViewType = SCNView
    
    @ObservedObject var handler: SCNViewMapHandler
    
    init() {
        let scnView = SCNView(frame: .zero)
        let cameraNode = SCNNode()
        let massCenter = SCNNode()
        let origin = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        
        self.handler = SCNViewMapHandler(scnView: scnView, cameraNode: cameraNode, massCenter: massCenter)
    }
    
    func makeUIView(context: Context) -> SCNView {
        handler.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    class Coordinator: NSObject {
        var parent: SCNViewMapContainer
        
        init(_ parent: SCNViewMapContainer) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

@available(iOS 17.0, *)
struct SCNViewMapContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewMapContainer()
    }
}
