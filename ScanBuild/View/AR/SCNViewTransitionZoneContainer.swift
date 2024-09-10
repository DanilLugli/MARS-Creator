import SwiftUI
import SceneKit
import ARKit
import RoomPlan
import CoreMotion
import ComplexModule

//final class SCNViewTransitionZoneContainer: UIViewRepresentable, ObservableObject {
//
//    typealias UIViewType = SCNView
//
//    var scnView = SCNView(frame: .zero)
//    var handler = HandleTap()
//
//    var cameraNode = SCNNode()
//    var massCenter = SCNNode()
//    var delegate = RenderDelegate()
//    var dimension = SCNVector3()
//
//    var rotoTraslation: [RotoTraslationMatrix] = []
//    var origin = SCNNode()
//    @State var rotoTraslationActive: Int = 0
//
//    var lastAddedBoxNode: SCNNode? = nil
//
//    init() {
//        massCenter.worldPosition = SCNVector3(0, 0, 0)
//        origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
//    }
//
//
//    func setCamera() {
//        scnView.scene?.rootNode.addChildNode(cameraNode)
//
//        cameraNode.camera = SCNCamera()
//
//        // Posiziona la camera sopra il massCenter
//        cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, massCenter.worldPosition.y + 10, massCenter.worldPosition.z)
//
//        // Configura la camera per la vista ortografica dall'alto
//        cameraNode.camera?.usesOrthographicProjection = true
//        cameraNode.camera?.orthographicScale = 10
//
//        // Ruota la camera per guardare verso il basso
//        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
//
//        // Crea una luce direzionale (opzionale)
//        let directionalLight = SCNNode()
//        directionalLight.light = SCNLight()
//        directionalLight.light!.type = .ambient
//        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
//        cameraNode.addChildNode(directionalLight)
//
//        // Imposta la camera come punto di vista
//        scnView.pointOfView = cameraNode
//
//        // Rimuovi il LookAtConstraint per evitare che la camera ruoti
//        cameraNode.constraints = []
//    }
//
//    func setMassCenter() {
//        var massCenter = SCNNode()
//        massCenter.worldPosition = SCNVector3(0, 0, 0)
//        if let nodes = scnView.scene?.rootNode
//            .childNodes(passingTest: {
//                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
//            }) {
//            massCenter = findMassCenter(nodes)
//        }
//        scnView.scene?.rootNode.addChildNode(massCenter)
//    }
//
//    func drawContent(borders: Bool) {
//        print(borders)
//
//        scnView.scene?
//            .rootNode
//            .childNodes(passingTest: {
//                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Floor0" && n.name! !=  "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
//            })
//            .forEach{
//                let material = SCNMaterial()
//                if $0.name == "Floor0" {
//                    material.diffuse.contents = UIColor.green
//                } else {
//                    material.diffuse.contents = UIColor.black
//                    if ($0.name!.prefix(5) == "Floor") {material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)}
//                    if ($0.name!.prefix(6) == "Transi") {
//                        print("Disegno \($0.name)")
//                        material.diffuse.contents = UIColor.red // Colore per il perimetro
//                        material.fillMode = .lines  // Questo renderà solo il contorno (wireframe) del nodo
//                    }
//                    if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") {material.diffuse.contents = UIColor.green}
//                    material.lightingModel = .physicallyBased
//                    $0.geometry?.materials = [material]
//
//                    if borders {
//                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
//                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
//                        $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
//                    }
//                }
//            }
//    }
//
//    func loadRoomMaps(room: Room, borders: Bool, usdzURL: URL) {
//        do {
//            scnView.scene = try SCNScene(url: usdzURL)
//            drawContent(borders: borders)
//            setMassCenter()
//            setCamera()
//        } catch {
//            print("Error loading scene from URL: \(error)")
//        }
//    }
//
//    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
//        let massCenter = SCNNode()
//        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
//        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
//        for n in nodes{
//            if (n.worldPosition.x < X[0]) {X[0] = n.worldPosition.x}
//            if (n.worldPosition.x > X[1]) {X[1] = n.worldPosition.x}
//            if (n.worldPosition.z < Z[0]) {Z[0] = n.worldPosition.z}
//            if (n.worldPosition.z > Z[1]) {Z[1] = n.worldPosition.z}
//        }
//        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
//        return massCenter
//    }
//
//    func setupCamera(cameraNode: SCNNode){
//        cameraNode.camera = SCNCamera()
//
//        scnView.scene?.rootNode.addChildNode(cameraNode)
//        let wall = scnView.scene?.rootNode
//            .childNodes(passingTest: {
//                n,_ in n.name != nil && n.name! == "Wall0"
//            })[0]
//
//        var X: [Float] = [1000000.0, -1000000.0]
//        var Z: [Float] = [1000000.0, -1000000.0]
//
//        let massCenter = SCNNode()
//
//        scnView.scene?.rootNode
//            .childNodes(passingTest: {
//                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
//            })
//            .forEach{
//                let material = SCNMaterial()
//                material.diffuse.contents = ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") ? UIColor.white : UIColor.black
//                material.lightingModel = .physicallyBased
//                $0.geometry?.materials = [material]
//                if ($0.worldPosition.x < X[0]) {X[0] = $0.worldPosition.x}
//                if ($0.worldPosition.x > X[1]) {X[1] = $0.worldPosition.x}
//                if ($0.worldPosition.z < Z[0]) {Z[0] = $0.worldPosition.z}
//                if ($0.worldPosition.z > Z[1]) {Z[1] = $0.worldPosition.z}
//            }
//        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
//        cameraNode.worldPosition = massCenter.worldPosition
//        cameraNode.worldPosition.y = 10
//        cameraNode.camera?.usesOrthographicProjection = true
//        cameraNode.camera?.orthographicScale = 20
//        cameraNode.rotation.y = wall!.rotation.y
//        cameraNode.rotation.w = wall!.rotation.w
//
//        let directionalLight = SCNNode()
//        directionalLight.light = SCNLight()
//        directionalLight.light!.type = .ambient
//        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
//        cameraNode.addChildNode(directionalLight)
//
//        scnView.pointOfView = cameraNode
//
//        scnView.scene?.rootNode.addChildNode(massCenter)
//
//        let vConstraint = SCNLookAtConstraint(target: massCenter)
//        cameraNode.constraints = [vConstraint]
//        directionalLight.constraints = [vConstraint]
//    }
//
//    func addBox(at position: SCNVector3) {
//        let box = SCNBox(width: 1.0, height: 2.0, length: 1.0, chamferRadius: 0.0)
//        let boxNode = SCNNode(geometry: box)
//        boxNode.position = position
//        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//        scnView.scene?.rootNode.addChildNode(boxNode)
//
//        lastAddedBoxNode = boxNode
//    }
//
//    func removeLastBox() {
//        if let boxNode = lastAddedBoxNode {
//            boxNode.removeFromParentNode()  // Rimuovi il nodo dalla scena
//            lastAddedBoxNode = nil  // Resetta il riferimento
//            print("Last SCNBox removed.")
//        } else {
//            print("No SCNBox to remove.")
//        }
//    }
//
//    // 1. Ruotare la SCNBox in senso orario (verso destra)
//    func rotateBoxClockwise() {
//        guard let boxNode = lastAddedBoxNode else { return }
//        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 2, z: 0, duration: 0.5)
//        boxNode.runAction(rotation)
//        print("Box rotated clockwise.")
//    }
//
//    // 1. Ruotare la SCNBox in senso antiorario (verso sinistra)
//    func rotateBoxCounterClockwise() {
//        guard let boxNode = lastAddedBoxNode else { return }
//        let rotation = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 2, z: 0, duration: 0.5)
//        boxNode.runAction(rotation)
//        print("Box rotated counter-clockwise.")
//    }
//
//
//
//    func makeUIView(context: Context) -> SCNView {
//        handler.scnView = scnView
//
//        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
//        scnView.addGestureRecognizer(pinchGesture)
//
//        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
//        scnView.addGestureRecognizer(panGesture)
//
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
//        scnView.addGestureRecognizer(tapGesture)
//
//        return scnView
//    }
//
//    func updateUIView(_ uiView: SCNView, context: Context) {}
//
//    func makeCoordinator() -> SCNViewContainerCoordinator {
//        SCNViewContainerCoordinator(self)
//    }
//
//    class SCNViewContainerCoordinator: NSObject {
//        var parent: SCNViewTransitionZoneContainer
//
//        init(_ parent: SCNViewTransitionZoneContainer) {
//            self.parent = parent
//        }
//
//        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//            guard let camera = parent.cameraNode.camera else { return }
//            let scale = gesture.scale
//            camera.orthographicScale /= Double(scale)
//            gesture.scale = 1
//        }
//
//        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
//            let translation = gesture.translation(in: parent.scnView)
//            parent.cameraNode.position.x -= Float(translation.x) * 0.01
//            parent.cameraNode.position.z += Float(translation.y) * 0.01
//            gesture.setTranslation(.zero, in: parent.scnView)
//        }
//
//        // Gestione del tap per aggiungere SCNBox alla scena
//        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
//            let location = gesture.location(in: parent.scnView)
//            let hitResults = parent.scnView.hitTest(location, options: nil)
//
//            if let hitResult = hitResults.first {
//                let position = hitResult.worldCoordinates
//                parent.addBox(at: position)
//            } else {
//                parent.addBox(at: SCNVector3(0, 0, 0)) // Posizione di default se non c'è un hit
//            }
//        }
//    }
//}


class SCNViewModel: ObservableObject {
    @Published var scnView = SCNView(frame: .zero)
    @Published var lastAddedBoxNode: SCNNode? = nil
    var cameraNode = SCNNode()
    
    init() {
        setupScene()
    }
    
    private func setupScene() {
        // Configura la scena qui (massCenter, camera, etc.)
        scnView.scene = SCNScene()
        setCamera()
    }
    
    func removeLastBox() {
            if let boxNode = lastAddedBoxNode {
                boxNode.removeFromParentNode()  // Rimuovi il nodo dalla scena
                lastAddedBoxNode = nil  // Resetta il riferimento
                print("Last SCNBox removed.")
            } else {
                print("No SCNBox to remove.")
            }
        }
        
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        cameraNode.camera = SCNCamera()
        cameraNode.worldPosition = SCNVector3(0, 10, 0)  // Esempio di posizionamento
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
        
        scnView.pointOfView = cameraNode
    }
    
    func drawContent(borders: Bool) {
        print(borders)
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Floor0" && n.name! !=  "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach{
                let material = SCNMaterial()
                if $0.name == "Floor0" {
                    material.diffuse.contents = UIColor.green
                } else {
                    material.diffuse.contents = UIColor.black
                    if ($0.name!.prefix(5) == "Floor") {material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)}
                    if ($0.name!.prefix(6) == "Transi") {
                        print("Disegno \($0.name)")
                        material.diffuse.contents = UIColor.red // Colore per il perimetro
                        material.fillMode = .lines  // Questo renderà solo il contorno (wireframe) del nodo
                    }
                    if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") {material.diffuse.contents = UIColor.green}
                    material.lightingModel = .physicallyBased
                    $0.geometry?.materials = [material]
                    
                    if borders {
                        $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                        $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                        $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                    }
                }
            }
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
    
    
    func loadRoomMaps(room: Room, borders: Bool, usdzURL: URL) {
        do {
            scnView.scene = try SCNScene(url: usdzURL)
            drawContent(borders: borders)
            setMassCenter()
            setCamera()
        } catch {
            print("Error loading scene from URL: \(error)")
        }
    }
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes{
            if (n.worldPosition.x < X[0]) {X[0] = n.worldPosition.x}
            if (n.worldPosition.x > X[1]) {X[1] = n.worldPosition.x}
            if (n.worldPosition.z < Z[0]) {Z[0] = n.worldPosition.z}
            if (n.worldPosition.z > Z[1]) {Z[1] = n.worldPosition.z}
        }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        return massCenter
    }
    
    func addBox(at position: SCNVector3) {
        let box = SCNBox(width: 1.0, height: 2.0, length: 1.0, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: box)
        boxNode.position = position
        boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        scnView.scene?.rootNode.addChildNode(boxNode)
        lastAddedBoxNode = boxNode
    }
    
    func rotateBoxClockwise() {
        guard let boxNode = lastAddedBoxNode else { return }
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi / 2, z: 0, duration: 0.5)
        boxNode.runAction(rotation)
    }
    
    func rotateBoxCounterClockwise() {
        guard let boxNode = lastAddedBoxNode else { return }
        let rotation = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 2, z: 0, duration: 0.5)
        boxNode.runAction(rotation)
    }
    
    // Puoi aggiungere tutte le altre funzioni come moveBox, stretchBox, etc.
    // 2. Allungare la SCNBox in larghezza
    func stretchBoxWidth() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.scale.x += 0.1
        print("Box stretched in width.")
    }
    
    // 3. Muovere la SCNBox a sinistra
    func moveBoxLeft() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.x -= 0.5
        print("Box moved left.")
    }
    
    // 3. Muovere la SCNBox a destra
    func moveBoxRight() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.x += 0.5
        print("Box moved right.")
    }
    
    // 3. Muovere la SCNBox in alto
    func moveBoxUp() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.z -= 0.5
        print("Box moved up.")
    }
    
    // 3. Muovere la SCNBox in basso
    func moveBoxDown() {
        guard let boxNode = lastAddedBoxNode else { return }
        boxNode.position.z += 0.5
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
            let hitResults = viewModel.scnView.hitTest(location, options: nil)
            
            if let hitResult = hitResults.first {
                let position = hitResult.worldCoordinates
                viewModel.addBox(at: position)
            } else {
                viewModel.addBox(at: SCNVector3(0, 0, 0))  // Default position
            }
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

