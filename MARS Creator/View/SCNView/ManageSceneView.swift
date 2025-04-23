//
//  ManageSceneView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 14/12/24.
//
import SwiftUI
import SceneKit

/// Manage Center Scene Node
func setMassCenter(scnView: SCNView, forNodeName nodeName: String? = nil) -> SCNNode {
    let massCenter = SCNNode()
    massCenter.worldPosition = SCNVector3(0, 0, 0)
    
    var nodesToConsider: [SCNNode] = []
    
    if let nodeName = nodeName,
       let targetNode = scnView.scene?.rootNode.childNode(withName: nodeName, recursively: true) {
        nodesToConsider = targetNode.childNodes
      
    } else {
        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
            guard let name = n.name else { return false }
            return name != "Room" && name != "Geom" && !name.hasSuffix("_grp")
        }) {
            nodesToConsider = nodes
        }
    }
    
    let calculatedMassCenter = findMassCenter(nodesToConsider)
    massCenter.worldPosition = calculatedMassCenter.worldPosition
    scnView.scene?.rootNode.addChildNode(massCenter)
    return massCenter
}

/// Calcola il centro di massa (centro geometrico) di un insieme di nodi
func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
    let massCenter = SCNNode()
    
    var totalX: Float = 0.0
    var totalY: Float = 0.0
    var totalZ: Float = 0.0
    var nodeCount: Float = 0.0
    
    // Somma le posizioni world di tutti i nodi
    for node in nodes {
        totalX += node.worldPosition.x
        totalY += node.worldPosition.y
        totalZ += node.worldPosition.z
        nodeCount += 1.0
    }
    
    // Se non ci sono nodi, restituisce (0,0,0)
    guard nodeCount > 0 else {
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        return massCenter
    }
    
    // Calcola la media delle coordinate
    let averageX = totalX / nodeCount
    let averageY = totalY / nodeCount
    let averageZ = totalZ / nodeCount
    
    massCenter.worldPosition = SCNVector3(averageX, averageY, averageZ)
    return massCenter
}

private func drawCross(at node: SCNNode) {
    let lineMaterial = SCNMaterial()
    lineMaterial.diffuse.contents = UIColor.green.withAlphaComponent(0.8) // Verde fluorescente
    
    let xLineGeometry = SCNCylinder(radius: 0.02, height: 1.0)
    xLineGeometry.materials = [lineMaterial]
    let xLineNode = SCNNode(geometry: xLineGeometry)
    xLineNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2) // Ruota lungo l'asse Z
    xLineNode.position = SCNVector3(0, 0, 0) // Centro
    
    // Linea lungo l'asse Z
    let zLineGeometry = SCNCylinder(radius: 0.02, height: 1.0)
    zLineGeometry.materials = [lineMaterial]
    let zLineNode = SCNNode(geometry: zLineGeometry)
    zLineNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0) // Ruota lungo l'asse X
    zLineNode.position = SCNVector3(0, 0, 0) // Centro
    
    // Aggiungi le linee al nodo
    node.addChildNode(xLineNode)
    node.addChildNode(zLineNode)
}

///Manage Camera Node
func setCamera(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
    
    cameraNode.camera = SCNCamera()
    cameraNode.worldPosition = SCNVector3(
        massCenter.worldPosition.x,
        massCenter.worldPosition.y + 20,
        massCenter.worldPosition.z
    )
    
    cameraNode.camera?.usesOrthographicProjection = true
    cameraNode.camera?.orthographicScale = 12
    cameraNode.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)

    scnView.scene?.rootNode.childNodes
        .filter { $0.light?.type == .ambient }
        .forEach { $0.removeFromParentNode() }

    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light!.type = .ambient
    ambientLight.light!.color = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    ambientLight.light!.intensity = 1200
    scnView.scene?.rootNode.addChildNode(ambientLight)
        
    scnView.pointOfView = cameraNode
    scnView.scene?.rootNode.addChildNode(cameraNode)
    cameraNode.constraints = []
}

func setCameraUp(scnView: SCNView, cameraNode: SCNNode, massCenter: SCNNode) {
    cameraNode.camera = SCNCamera()
    
    // Add the camera node to the scene
    scnView.scene?.rootNode.addChildNode(cameraNode)
    
    // Position the camera at the same Y level as the mass center, and at a certain distance along the Z-axis
    let cameraDistance: Float = 10.0 // Distance in front of the mass center
    let cameraHeight: Float = massCenter.worldPosition.y + 2.0 // Slightly above the mass center
    
    cameraNode.worldPosition = SCNVector3(massCenter.worldPosition.x, cameraHeight, massCenter.worldPosition.z + cameraDistance)
    
    // Set the camera to use perspective projection
    cameraNode.camera?.usesOrthographicProjection = false
    
    // Optionally set the field of view
    cameraNode.camera?.fieldOfView = 60.0 // Adjust as needed
    
    // Make the camera look at the mass center
//        let lookAtConstraint = SCNLookAtConstraint(target: massCenter)
//        lookAtConstraint.isGimbalLockEnabled = true
//        cameraNode.constraints = [lookAtConstraint]
    
    // Add ambient light to the scene
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light!.type = .ambient
    ambientLight.light!.color = UIColor(white: 0.5, alpha: 1.0)
    scnView.scene?.rootNode.addChildNode(ambientLight)
    
    // Add a directional light to simulate sunlight
    let directionalLight = SCNNode()
    directionalLight.light = SCNLight()
    directionalLight.light!.type = .directional
    directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
    directionalLight.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0) // Adjust angle as needed
    scnView.scene?.rootNode.addChildNode(directionalLight)
    
    // Set the point of view of the scene to the camera node
    scnView.pointOfView = cameraNode
}

func drawSceneObjects(scnView: SCNView, borders: Bool, nodeOrientation: Bool) {
    
    var drawnNodes = Set<String>()
    
    scnView.scene?
        .rootNode
        .childNodes(passingTest: { n, _ in
            n.name != nil &&
            n.name! != "Room" &&
            n.name! != "Floor0" &&
            n.name! != "Geom" &&
            String(n.name!.suffix(4)) != "_grp" &&
            n.name! != "__selected__"
        })
        .forEach {
            guard let nodeName = $0.name else { return }  
           
            if nodeName.lowercased().hasPrefix("clone") {
                return
            }

            let material = SCNMaterial()

            switch nodeName {
            case "Floor0":
                material.diffuse.contents = UIColor.green
            default:
                material.diffuse.contents = UIColor.black

                let prefix4 = nodeName.prefix(4)
                let prefix5 = nodeName.prefix(5)
                let prefix6 = nodeName.prefix(6)

                switch prefix4 {
                case "Door":
                    if nodeOrientation{
                        material.diffuse.contents = UIColor.blue
                    }else{
                        material.diffuse.contents = UIColor.black
                    }
                    $0.position.y += 2
                case "Tabl":
                    material.diffuse.contents = UIColor.brown
                case "Open":
                    if nodeOrientation{
                        material.diffuse.contents = UIColor.blue
                    }else{
                        material.diffuse.contents = UIColor.black
                    }
                    $0.position.y += 2
                case "Wind":
                    if nodeOrientation{
                        material.diffuse.contents = UIColor.purple
                    }else{
                        material.diffuse.contents = UIColor.black
                    }
                    $0.position.y += 2
                case "Chai":
                    material.diffuse.contents = UIColor.brown.withAlphaComponent(0.4)
                case "Stor":
                    material.diffuse.contents = UIColor.systemGray
                case "Sofa":
                    material.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 0.6)
                case "Tele":
                    material.diffuse.contents = UIColor.orange
                case "Wall":
                    material.diffuse.contents = UIColor.black
                    //$0.scale.z *= 0.6
                default:
                    break
                }

                switch prefix5 {
                case "Floor":
                    material.diffuse.contents = UIColor.white.withAlphaComponent(0)
                default:
                    break
                }

                switch prefix6 {
                case "Transi":
                    material.diffuse.contents = UIColor.white
                default:
                    break
                }
            }

            material.lightingModel = .physicallyBased
            $0.geometry?.materials = [material]

            drawnNodes.insert(nodeName)
        }
}


