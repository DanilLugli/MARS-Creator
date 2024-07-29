import Foundation
import SwiftUI
import SceneKit

struct MatrixView: View {
    
    @State var selectedLocalNodeName = ""
    @State var selectedGlobalNodeName = ""
    
    @State var selectedLocalNode: SCNNode?
    @State var selectedGlobalNode: SCNNode?
    
    var globalView: SCNViewContainer
    var localView: SCNViewContainer
    var localMaps: [URL]?
    
    @State var globalNodes: [String]
    @State var localNodes: [String] = []
    
    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = []
    
    @State var apiResponseCode = ""
    
    @State var responseFromServer = false
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["": ""])
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    
    @State private var mapName: String = ""
    
    @State private var selectedMap: URL = URL(fileURLWithPath: "")
    @State private var availableMaps: [String] = []
    @State private var filteredLocalMaps: [String] = []
    
    @ObservedObject var floor: Floor
    
    func printOriginalDimensionsOfSelectedNode(selectedNode: SCNNode) {
        if let geometry = selectedNode.geometry {
            switch geometry {
            case let box as SCNBox:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Box, Dimensioni originali: larghezza: \(box.width), altezza: \(box.height), lunghezza: \(box.length)")
            case let sphere as SCNSphere:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Sphere, Diametro originale: \(sphere.radius * 2)")
            case let cylinder as SCNCylinder:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cylinder, Altezza originale: \(cylinder.height), Diametro originale: \(cylinder.radius * 2)")
            case let cone as SCNCone:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cone, Altezza originale: \(cone.height), Diametro alla base originale: \(cone.topRadius * 2)")
            case let plane as SCNPlane:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Plane, Dimensioni originali: larghezza: \(plane.width), altezza: \(plane.height)")
            default:
                print("Geometria non supportata per il calcolo delle dimensioni.")
            }
        } else {
            print("Il nodo selezionato non ha una geometria associata.")
        }
    }
    
    init(floor: Floor) {
        self.floor = floor
        globalView = SCNViewContainer()
        localView = SCNViewContainer()
        globalView.loadgeneralMap(borders: false, usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz"))
        
        globalNodes = globalView
            .scnView
            .scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Geom" &&
                String(n.name!.suffix(4)) != "_grp"
            }).map { node in node.name ?? "nil" } ?? []
        
        localMaps = getUSDZMapURLs(for: floor)
    }
    
    func getUSDZMapURLs(for floor: Floor) -> [URL] {
        var usdzMapURLs: [URL] = []
        floor.rooms.forEach { room in
            usdzMapURLs.append(room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
        }
        return usdzMapURLs
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("CREATE MATRIX").bold().font(.largeTitle).foregroundColor(.white)
                    Text("GLOBAL Map").bold().font(.title3).foregroundColor(.white)
                }
                
                HStack {
                    Button("+") {
                        globalView.zoomIn()
                    }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(8)
                    Button("-") {
                        globalView.zoomOut()
                    }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(8)
                }
                
                globalView
                    .border(Color.white)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
                
                HStack {
                    Picker("Choose Global Node", selection: $selectedGlobalNodeName) {
                        Text("Choose Global Node")
                        ForEach(globalNodes, id: \.self) {Text($0)}
                    }.onChange(of: selectedGlobalNodeName, perform: { _ in
                        globalView.changeColorOfNode(nodeName: selectedGlobalNodeName, color: UIColor.green)
                        
                        let firstTwoLetters = String(selectedGlobalNodeName.prefix(2))
                        
                        localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n, _ in n.name != nil && n.name!.starts(with: firstTwoLetters) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: {a, b in a.scale.x > b.scale.x})
                        .map{node in node.name ?? "nil"} ?? []
                        
                        selectedGlobalNode = globalView.scnView.scene?.rootNode.childNodes(passingTest: {n,_ in n.name != nil && n.name! == selectedGlobalNodeName}).first
                    })
                    
                    if let _size = selectedGlobalNode?.scale {
                        Text("\(_size.x) \(_size.y) \(_size.z)")
                    }
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                
                if let _localMaps = localMaps {
                    HStack {
                        Text("LOCAL Map").bold().font(.title3).foregroundColor(.white)
                    }
                    Picker("", selection: $selectedMap) {
                        Text("Choose Local Map").foregroundColor(.white)
                        ForEach(_localMaps, id: \.self) { map in
                            Text(map.deletingPathExtension().lastPathComponent) // Display room name without .usdz extension
                        }
                    }.onChange(of: selectedMap, perform: { _ in
                        
                        localView.loadRoomMaps(name: selectedMap.lastPathComponent, borders: false, usdzURL: selectedMap)
                        
                        let numbersCharacterSet = CharacterSet.decimalDigits
                        let mapName = selectedMap.lastPathComponent.components(separatedBy: numbersCharacterSet).joined()
                        
                        globalView.loadgeneralMap(borders: false, usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("Taverna.usdz"))
                        
                        localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: { a, b in a.scale.x > b.scale.x })
                        .map { node in node.name ?? "nil" } ?? []
                        print("Child Nodes: \(localView.scnView.scene?.rootNode.childNodes)")
                    })
                }
                
                if selectedMap != nil {
                    HStack {
                        Button("+") {
                            localView.zoomIn()
                        }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
                        Button("-") {
                            localView.zoomOut()
                        }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
                    }
                    
                    localView
                        .border(Color.white)
                        .padding()
                        .shadow(color: Color.gray, radius: 3)
                    
                    HStack {
                        Picker("", selection: $selectedLocalNodeName) {
                            Text("Choose Local Node").foregroundColor(.white)
                            ForEach(localNodes, id: \.self) { Text($0) }
                        }.onChange(of: selectedLocalNodeName, perform: { _ in
                            localView.changeColorOfNode(nodeName: selectedLocalNodeName, color: UIColor.green)
                            selectedLocalNode = localView.scnView.scene?.rootNode.childNodes(passingTest: { n, _ in n.name != nil && n.name! == selectedLocalNodeName }).first
                            let firstTwoLettersLocal = String(selectedLocalNodeName.prefix(2))
                            globalNodes = globalView.scnView.scene?.rootNode.childNodes(passingTest: {
                                n, _ in n.name != nil && n.name!.starts(with: firstTwoLettersLocal) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                            })
                            .sorted(by: { a, b in a.scale.x > b.scale.x })
                            .map { node in node.name ?? "nil" } ?? []
                            globalNodes = orderBySimilarity(
                                node: selectedLocalNode!,
                                listOfNodes: globalView.scnView.scene!.rootNode.childNodes(passingTest: {
                                    n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "selected"
                                })
                            ).map { node in node.name ?? "nil" }
                        })
                        if let _size = selectedLocalNode?.scale {
                            Text("(_size.x) (_size.y) (_size.z)")
                        }
                    }
                }
                HStack {
                    if let _selectedLocalNode = selectedLocalNode,
                       let _selectedGlobalNode = selectedGlobalNode {
                        Button("confirm relation") {
                            matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))
                            print(_selectedLocalNode)
                            print(_selectedGlobalNode)
                            print(selectedMap.lastPathComponent ?? "")
                            print(matchingNodesForAPI)
                        }.buttonStyle(.bordered)
                            .background(Color(red: 240/255, green: 151/255, blue: 45/255))
                            .cornerRadius(6)
                            .bold()
                    }
                    Text("matched nodes: \(matchingNodesForAPI.count)")
                    if matchingNodesForAPI.count >= 3 {
                        Button("ransac Alignment API") {
                            Task {
                                print(selectedMap.lastPathComponent ?? "")
                                print(matchingNodesForAPI)
                                responseFromServer = true
                            }
                        }.buttonStyle(.bordered)
                            .background(Color(red: 255/255, green: 235/255, blue: 205/255))
                            .cornerRadius(6)
                            .bold()
                    }
                }
            }.background(Color.customBackground)
        }
    }
    
    func orderBySimilarity(node: SCNNode, listOfNodes: [SCNNode]) -> [SCNNode] {
        print(node.scale)
        var result: [(SCNNode, Float)] = []
        for n in listOfNodes {
            result.append((n, simd_fast_distance(n.simdScale, node.simdScale)))
        }
        return result.sorted(by: { a, b in a.1 < b.1 }).map { $0.0 }
    }}

struct MatrixView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        let floor = firstBuildingIndex.floors.first!
        return MatrixView(floor: floor)
    }
}
