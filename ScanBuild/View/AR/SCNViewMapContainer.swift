
import SwiftUI
import SceneKit

class SCNViewMapHandler: ObservableObject {
    @Published var rotoTraslation: [RotoTraslationMatrix] = []
    
    var scnView: SCNView
    var cameraNode: SCNNode
    var massCenter: SCNNode
    
    init(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
        self.scnView = scnView
        self.cameraNode = cameraNode
        self.massCenter = massCenter
    }
    
    func loadMaps(floor: Floor, roomURLs: [URL], borders: Bool) {
        do {
            let floorFileURL = floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
            let floorURL = floor.floorURL
            
            scnView.scene = try SCNScene(url: floorFileURL)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
            
            if let matrices = loadRotoTraslationMatrix(from: floorURL.appendingPathComponent("Taverna.json")) {
                print("MATRICES: ")
                print(matrices)
                print("\n\n\n")
                self.rotoTraslation.append(contentsOf: matrices)
                print(self.rotoTraslation.count)
            } else {
                print("Failed to load RotoTraslationMatrix from JSON file")
            }
            
            for (index, roomURL) in roomURLs.enumerated() {
                print("\n\n\n")
                print(roomURL)
                let roomScene = try SCNScene(url: roomURL)
                
                // Trova il nodo chiamato "floor0" all'interno della stanza
                if let roomNode = roomScene.rootNode.childNode(withName: "Floor0", recursively: true) {
                    print("CHECK:\n\n")
                    print(index)
                    print(self.rotoTraslation.count)
                    
                    if index < self.rotoTraslation.count {
                        let rotoTraslationMatrix = self.rotoTraslation[index]
                        print("Transformation for node \(roomNode.name ?? "Unnamed Node") at index \(index):")
                        print("Translation matrix: \(rotoTraslationMatrix.translation)")
                        print("Rotation matrix (r_Y): \(rotoTraslationMatrix.r_Y)")
                        print(self.rotoTraslation[index])
                        applyRotoTraslation(to: roomNode, with: self.rotoTraslation[index])
                    }
                    
                    roomNode.name = roomURL.deletingPathExtension().lastPathComponent
                    
                    scnView.scene?.rootNode.addChildNode(roomNode)
                    
                    // Stampa le informazioni del nodo radice e la sua trasformazione
                    print("Root node: \(roomScene.rootNode)")
                    print("Transform of root node: \(roomScene.rootNode.transform)")
                    
                    // Stampa le informazioni del nodo specifico "floor0" e la sua trasformazione
                    print("Node 'floor0': \(roomNode)")
                    print("Transform of node 'floor0': \(roomNode.transform)")
                } else {
                    print("Node 'floor0' not found in scene: \(roomURL)")
                }
            }
        } catch {
            print("Error loading scene from URL: \(error)")
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
                n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach {
                let material = SCNMaterial()
                
                if $0.name == "Floor0" {
                    material.diffuse.contents = UIColor.blue
                } else {
                    material.diffuse.contents = UIColor.black
                    if ($0.name!.prefix(5) == "Floor") {
                        material.diffuse.contents = UIColor.green.withAlphaComponent(0.2)
                    }
                    if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") {
                        material.diffuse.contents = UIColor.orange
                    }
                }
                
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
                if borders {
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
            }
    }
    
    func zoomIn() { cameraNode.camera?.orthographicScale -= 0.5 }
    
    func zoomOut() { cameraNode.camera?.orthographicScale += 0.5 }
    
    func setCamera() {
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
    
    func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: {
            n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
        }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    func applyRotoTraslation(to node: SCNNode, with rotoTraslation: RotoTraslationMatrix) {
        
        print("NODE: ")
        print(node)
        node.simdWorldTransform.columns.3 = node.simdWorldTransform.columns.3 * rotoTraslation.translation
        
        let r_Y = simd_float3x3([
            simd_float3(rotoTraslation.r_Y.columns.0.x, rotoTraslation.r_Y.columns.0.y, rotoTraslation.r_Y.columns.0.z),
            simd_float3(rotoTraslation.r_Y.columns.1.x, rotoTraslation.r_Y.columns.1.y, rotoTraslation.r_Y.columns.1.z),
            simd_float3(rotoTraslation.r_Y.columns.2.x, rotoTraslation.r_Y.columns.2.y, rotoTraslation.r_Y.columns.2.z),
        ])
        
        var rot = simd_float3x3([
            simd_float3(node.simdWorldTransform.columns.0.x, node.simdWorldTransform.columns.0.y, node.simdWorldTransform.columns.0.z),
            simd_float3(node.simdWorldTransform.columns.1.x, node.simdWorldTransform.columns.1.y, node.simdWorldTransform.columns.1.z),
            simd_float3(node.simdWorldTransform.columns.2.x, node.simdWorldTransform.columns.2.y, node.simdWorldTransform.columns.2.z),
        ])
        
        rot = r_Y * rot
        
        node.simdWorldTransform.columns.0 = simd_float4(
            rot.columns.0.x,
            rot.columns.0.y,
            rot.columns.0.z,
            node.simdWorldTransform.columns.0.w
        )
        node.simdWorldTransform.columns.1 = simd_float4(
            rot.columns.1.x,
            rot.columns.1.y,
            rot.columns.1.z,
            node.simdWorldTransform.columns.1.w
        )
        node.simdWorldTransform.columns.2 = simd_float4(
            rot.columns.2.x,
            rot.columns.2.y,
            rot.columns.2.z,
            node.simdWorldTransform.columns.2.w
        )
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
