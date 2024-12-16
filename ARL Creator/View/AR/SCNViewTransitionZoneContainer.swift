import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

class SCNViewModel: ObservableObject, MoveDimensionObject{
    
    @Published var scnView = SCNView(frame: .zero)
    @Published var lastAddedBoxNode: SCNNode? = nil
    var cameraNode = SCNNode()
    var massCenter: SCNNode = SCNNode()

    
    init() {
        setupScene()
    }
    
    private func setupScene() {
        scnView.scene = SCNScene()
        self.massCenter.worldPosition = SCNVector3(0, 0, 0)
    }
    
    func removeLastBox() {
        if let boxNode = lastAddedBoxNode {
            boxNode.removeFromParentNode()
            lastAddedBoxNode = nil
        } else {
            print("No SCNBox to remove.")
        }
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
                    material.diffuse.contents = UIColor.white
                } else {
                    material.diffuse.contents = UIColor.black
                }
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                
                // Applica le modifiche di scala se richiesto
//                if borders {
//                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
//                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
//                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
//                }
            }
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in n.name?.hasPrefix("Floor") ?? false
            })
            .forEach { node in
                node.removeFromParentNode()
            }
    }
    
    func loadRoomMaps(room: Room, borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            drawContent(borders: borders)
            setMassCenter(scnView: self.scnView)
            setCamera(scnView: self.scnView, cameraNode: self.cameraNode, massCenter: self.massCenter)
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }

    func addBox(at position: SCNVector3) {
        if lastAddedBoxNode != nil {
            print("A box has already been added. Remove it before adding a new one.")
            return  // Esci dalla funzione se esiste già un box
        }
        
        let box = SCNBox(width: 1.0, height: 2.0, length: 1.0, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = position
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        scnView.scene?.rootNode.addChildNode(boxNode)
        lastAddedBoxNode = boxNode
    }
    
    func handleTap(at location: CGPoint) {
        print("Tap detected at location: \(location)")
        
        // Hit test to find the tapped point in the scene
        let hitResults = scnView.hitTest(location, options: nil)
        if let hitResult = hitResults.first {
            let position = hitResult.worldCoordinates
            print("Tapped position in scene: \(position)")
            addBox(at: position)
        } else {
            print("No node found at tap location, placing box at default position (0, 0, 0)")
            addBox(at: SCNVector3(0, 0, 0))  // Default position
        }
    }
    
    func incrementWidht(by: Int) {
        self.stretchBoxWidth(widthFactor: by)
    }
    
    func rotateClockwise() {
        self.rotateBoxClockwise()
    }
    
    func rotateCounterClockwise() {
        self.rotateBoxCounterClockwise()
    }
    
    func moveUp() {
        self.moveBoxUp()
    }
    
    func moveDown() {
        self.moveBoxDown()
    }
    
    func moveLeft() {
        self.moveBoxLeft()
    }
    
    func moveRight() {
        self.moveBoxRight()
    }
    
    func rotateBoxClockwise() {
        guard let boxNode = lastAddedBoxNode else { return }
        
        let oneDegreeInRadians = CGFloat.pi / 180
        
        boxNode.eulerAngles.y += Float(oneDegreeInRadians)
        
        print("Box rotated 1 degree clockwise.")
    }

    func rotateBoxCounterClockwise() {
        guard let boxNode = lastAddedBoxNode else { return }
        
        // 1 grado in radianti (negativi per rotazione in senso antiorario)
        let oneDegreeInRadians = CGFloat.pi / 180
        
        // Aggiorna manualmente l'angolo di rotazione del nodo sull'asse Y
        boxNode.eulerAngles.y -= Float(oneDegreeInRadians)
        
        print("Box rotated 1 degree counter-clockwise.")
    }
    
    func stretchBoxWidth(widthFactor: Int) {
        guard let boxNode = lastAddedBoxNode else { return }
        
        // Assicurati che l'input sia compreso tra 0 e 100
        let clampedWidthFactor = max(0, min(widthFactor, 100))
        
        // La larghezza iniziale è sempre 1.0, quindi si basa su questo valore
        let newWidth = 1.0 * (1.0 + (Float(clampedWidthFactor) / 100.0) * 7.0)
        
        // Applica la nuova larghezza al nodo
        boxNode.scale.x = newWidth
        
        print("Box stretched to widthFactor \(clampedWidthFactor) with new width \(newWidth).")
        
    }
    
    func moveBoxLeft() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.x -= 0.1
        print("Box moved left.")
    }
    
    func moveBoxRight() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.x += 0.1
        print("Box moved right.")
    }
    
    func moveBoxUp() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.z -= 0.1
        print("Box moved up.")
    }
    
    func moveBoxDown() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.z += 0.1
        print("Box moved down.")
    }
}

struct SCNViewTransitionZoneContainer: UIViewRepresentable {
    
    @ObservedObject var viewModel: SCNViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        viewModel.scnView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        viewModel.scnView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        viewModel.scnView.addGestureRecognizer(tapGesture)
        
        return viewModel.scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> SCNViewContainerCoordinator {
        SCNViewContainerCoordinator(self, viewModel: viewModel)
    }
    
    class SCNViewContainerCoordinator: NSObject {
        var parent: SCNViewTransitionZoneContainer
        var viewModel: SCNViewModel
        
        init(_ parent: SCNViewTransitionZoneContainer, viewModel: SCNViewModel) {
            self.parent = parent
            self.viewModel = viewModel
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = viewModel.cameraNode.camera else { return }
            let scale = gesture.scale
            camera.orthographicScale /= Double(scale)
            gesture.scale = 1
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: viewModel.scnView)
            viewModel.cameraNode.position.x -= Float(translation.x) * 0.01
            viewModel.cameraNode.position.z += Float(translation.y) * 0.01
            gesture.setTranslation(.zero, in: viewModel.scnView)
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: viewModel.scnView)
            viewModel.handleTap(at: location)
        }
    }
}

class HandleTap: UIViewController {
    var scnView: SCNView?
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        print("handleTap")
        
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView!.hitTest(p, options: nil)
        if let tappedNode = hitResults.first?.node {
            print(tappedNode)
        }
    }
}

