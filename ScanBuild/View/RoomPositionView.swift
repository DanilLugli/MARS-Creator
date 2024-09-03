import Foundation
import SwiftUI
import SceneKit

struct RoomPositionView: View {

    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State var selectedRoomNode: SCNNode?
    @State var selectedFloorNode: SCNNode?
    
    @State var selectedRoomNodeName = ""
    @State var selectedFloorNodeName = ""
    
    var floorView: SCNViewContainer
    var roomView: SCNViewContainer
    var roomsMaps: [URL]?
    
    @State var floorNodes: [String]
    @State var roomNodes: [String]
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    @State private var showAlert = false
    @State private var showSheet = false
    
    @State private var selectedMap: URL = URL(fileURLWithPath: "")
    @State private var filteredLocalMaps: [String] = []
    
    @State var responseFromServer = false {
        didSet {
            if responseFromServer {
                showSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showAlert = false
                    responseFromServer = false
                }
            }
        }
    }
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["": ""])
    @State var apiResponseCode = ""
    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = []
    
    init(floor: Floor, room: Room) {
        self.floor = floor
        self.room = room
        
        floorView = SCNViewContainer()
        roomView = SCNViewContainer()
        
        floorView.loadFloorPlanimetry(borders: false, usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz"))
        
        roomView.loadRoomMaps(name: room.name, borders: false, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
        
        if let rootNode = floorView.scnView.scene?.rootNode {
            print("Printing all nodes in floorView's rootNode:")
            rootNode.enumerateChildNodes { (node, _) in
                let nodeName = node.name ?? "Unnamed Node"
                let nodeSize = SCNVector3(
                    node.boundingBox.max.x - node.boundingBox.min.x,
                    node.boundingBox.max.y - node.boundingBox.min.y,
                    node.boundingBox.max.z - node.boundingBox.min.z
                )  // Dimensione del nodo
                let nodePosition = node.position  // Posizione del nodo
            }
        } else {
            print("No nodes found in floorView's rootNode.")
        }
        
//        floorNodes = Array(Set(floorView
//            .scnView
//            .scene?
//            .rootNode
//            .childNodes(passingTest: {
//                n, _ in n.name != nil &&
//                n.name! != "Room" &&
//                n.name! != "Geom" &&
//                String(n.name!.suffix(4)) != "_grp"
//            }).compactMap { node in node.name } ?? []))
        
        floorNodes = Array(Set(floorView
            .scnView
            .scene?
            .rootNode
            .childNodes(passingTest: { n, _ in
                if let nodeName = n.name {
                    return nodeName != "Room" &&
                           nodeName != "Geom" &&
                           !nodeName.hasSuffix("_grp") &&
                           !nodeName.hasPrefix("unidentified")
                }
                return false
            }).compactMap { node in node.name } ?? []))
            .sorted()
        
        if let nodes = roomView.scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
            n.name != nil &&
            n.name! != "Room" &&
            n.name! != "Geom" &&
            String(n.name!.suffix(4)) != "_grp"
        }) {
            let names = nodes.compactMap { $0.name }
            print("Collected node names: \(names)")

            // Rimuovere i duplicati utilizzando un dizionario per tracciare i nomi già visti
            var uniqueNamesDict = [String: Bool]()
            var uniqueNamesArray = [String]()

            for name in names {
                if uniqueNamesDict[name] == nil {
                    uniqueNamesDict[name] = true
                    uniqueNamesArray.append(name)
                }
            }
            
            roomNodes = uniqueNamesArray.sorted()

            print("Unique node names: \(roomNodes)")
        } else {
            roomNodes = []
        }
    }
    
//    func printOriginalDimensionsOfSelectedNode(selectedNode: SCNNode) {
//        if let geometry = selectedNode.geometry {
//            switch geometry {
//            case let box as SCNBox:
//                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Box, Dimensioni originali: larghezza: \(box.width), altezza: \(box.height), lunghezza: \(box.length)")
//            case let sphere as SCNSphere:
//                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Sphere, Diametro originale: \(sphere.radius * 2)")
//            case let cylinder as SCNCylinder:
//                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cylinder, Altezza originale: \(cylinder.height), Diametro originale: \(cylinder.radius * 2)")
//            case let cone as SCNCone:
//                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cone, Altezza originale: \(cone.height), Diametro alla base originale: \(cone.topRadius * 2)")
//            case let plane as SCNPlane:
//                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Plane, Dimensioni originali: larghezza: \(plane.width), altezza: \(plane.height)")
//            default:
//                print("Geometria non supportata per il calcolo delle dimensioni.")
//            }
//        } else {
//            print("Il nodo selezionato non ha una geometria associata.")
//        }
//    }

    var body: some View {
        NavigationStack {
            VStack {
                ConnectedDotsView(
                    labels: ["1° Association", "2° Association", "3° Association", "Confirm"],
                    progress: min(matchingNodesForAPI.count + 1, 4)
                )
                
                VStack {
                    Text("Floor: \(floor.name)").bold().font(.title3).foregroundColor(.white)
                }
                
                ZStack {
                    floorView
                        .border(Color.white)
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: Color.gray, radius: 3)
                    
                    VStack {
                        HStack {
                            HStack {
                                Button(action: {
                                    floorView.zoomIn()
                                }) {
                                    Image(systemName: "plus")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    floorView.zoomOut()
                                }) {
                                    Image(systemName: "minus")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                                
                            }.padding()
                            HStack {
                                Button(action: {
                                    floorView.moveMapRight()
                                }) {
                                    Image(systemName: "arrow.left")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    floorView.moveMapLeft()
                                }) {
                                    Image(systemName: "arrow.right")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                            }.padding()
                            HStack {
                                Button(action: {
                                    floorView.moveMapUp()
                                }) {
                                    Image(systemName: "arrow.up")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                                
                                Button(action: {
                                    floorView.moveMapDown()
                                }) {
                                    Image(systemName: "arrow.down")
                                        .bold()
                                        .foregroundColor(.white) // Colore del simbolo
                                }
                                .buttonStyle(.bordered)
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                            }.padding()
                        }
                        Spacer() // Push buttons to the top
                    }
                }
                
                HStack {
                    Picker("Choose Floor Node", selection: $selectedFloorNodeName) {
                        Text("Choose Floor Node")
                        ForEach(floorNodes, id: \.self) { Text($0) }
                    }.onChange(of: selectedFloorNodeName, perform: { _ in
                        floorView.changeColorOfNode(nodeName: selectedFloorNodeName, color: UIColor.green)
                        
                        let firstTwoLetters = String(selectedFloorNodeName.prefix(4))
                        
                        roomNodes = roomView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n, _ in n.name != nil && n.name!.starts(with: firstTwoLetters) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: { a, b in
                            let sizeA = SCNVector3(
                                a.boundingBox.max.x - a.boundingBox.min.x,
                                a.boundingBox.max.y - a.boundingBox.min.y,
                                a.boundingBox.max.z - a.boundingBox.min.z
                            )
                            
                            let sizeB = SCNVector3(
                                b.boundingBox.max.x - b.boundingBox.min.x,
                                b.boundingBox.max.y - b.boundingBox.min.y,
                                b.boundingBox.max.z - b.boundingBox.min.z
                            )
                            
                            // Ordina per la lunghezza, in questo caso consideriamo la lunghezza lungo l'asse X
                            return sizeA.x > sizeB.x
                        })
                        .map { node in node.name ?? "nil" } ?? []
                        
                        selectedFloorNode = floorView.scnView.scene?.rootNode.childNodes(passingTest: { n, _ in n.name != nil && n.name! == selectedFloorNodeName }).first
                        
                        print(selectedFloorNode)
                    })
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                HStack {
                    Text("Room: \(room.name)").bold().font(.title3).foregroundColor(.white)
                }
                
                if room != nil {
                    ZStack {
                        roomView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                        
                        VStack {
                            HStack {
                                HStack {
                                    Button(action: {
                                        roomView.zoomIn()
                                    }) {
                                        Image(systemName: "plus")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                    
                                    Button(action: {
                                        roomView.zoomOut()
                                    }) {
                                        Image(systemName: "minus")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                    
                                }.padding()
                                HStack {
                                    Button(action: {
                                        roomView.moveMapRight()
                                    }) {
                                        Image(systemName: "arrow.left")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                    
                                    Button(action: {
                                        roomView.moveMapLeft()
                                    }) {
                                        Image(systemName: "arrow.right")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                }.padding()
                                HStack {
                                    Button(action: {
                                        roomView.moveMapUp()
                                    }) {
                                        Image(systemName: "arrow.up")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                    
                                    Button(action: {
                                        roomView.moveMapDown()
                                    }) {
                                        Image(systemName: "arrow.down")
                                            .bold()
                                            .foregroundColor(.white) // Colore del simbolo
                                    }
                                    .buttonStyle(.bordered)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                }.padding()
                            }
                            Spacer() // Push buttons to the top
                        }
                    }
                    
                    HStack {
                        Picker("Choose Room Node", selection: $selectedRoomNodeName) {
                            Text("Choose Room Node")
                            //ForEach(roomNodes, id: \.self) { Text($0) }
                            ForEach(roomNodes, id: \.self) { node in
                                //print("Node ID: \(node.name)") // Debug output
                                Text(node).tag(node)
                            }
                        }.onChange(of: selectedRoomNodeName, perform: { _ in
                            
                            roomView.changeColorOfNode(nodeName: selectedRoomNodeName, color: UIColor.green)
                            
                            selectedRoomNode = roomView.scnView.scene?.rootNode.childNodes(passingTest: {
                                n, _ in n.name != nil && n.name! == selectedRoomNodeName
                            }).first
                            
                            print(selectedRoomNode)
                            
                            let firstTwoLettersLocal = String(selectedRoomNodeName.prefix(2))
                            
                            floorNodes = floorView.scnView.scene?.rootNode.childNodes(passingTest: {
                                n, _ in n.name != nil && n.name!.starts(with: firstTwoLettersLocal) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                            })
                            .sorted(by: { a, b in a.scale.x > b.scale.x })
                            .map { node in node.name ?? "nil" } ?? []
                            
                            floorNodes = orderBySimilarity(
                                node: selectedRoomNode!,
                                listOfNodes: floorView.scnView.scene!.rootNode.childNodes(passingTest: {
                                    n, _ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "selected"
                                })
                            ).map { node in node.name ?? "nil" }
                        })
                    }
                }
                
                HStack {
                    if let _selectedLocalNode = selectedRoomNode,
                       let _selectedGlobalNode = selectedFloorNode {
                        Button("Confirm Relation") {
                            matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))
                            
                            selectedRoomNode = nil
                            selectedFloorNode = nil
                            print(_selectedLocalNode)
                            print(_selectedGlobalNode)
                            print(selectedMap.lastPathComponent)
                            print(matchingNodesForAPI)
                            
                        }.buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4)
                            .cornerRadius(10))
                            .bold()
                    }
                    if matchingNodesForAPI.count >= 3 {
                        Button("Create Matrix") {
                            Task {
                                print(matchingNodesForAPI)
                                response = try await fetchAPIConversionLocalGlobal(localName: room.name, nodesList: matchingNodesForAPI)
                                if let httpResponse = response.0 {
                                    print("Status code: \(httpResponse.statusCode)")
                                    print("Response JSON: \(response.1)")
                                } else {
                                    print("Error: \(response.1)")
                                }
                                
                                print(selectedMap.lastPathComponent)
                                print(matchingNodesForAPI)
                                
                                //saveConversionGlobalLocal(response.1, floor.floorURL, floor)
                                responseFromServer = true
                                showAlert = true
                            }
                        }.buttonStyle(.bordered)
                            .frame(width: 150, height: 50)
                            .foregroundColor(.white)
                            .background(Color(red: 62/255, green: 206/255, blue: 76/255))
                            .cornerRadius(6)
                            .bold()
                    }
                }
            
            }
            .background(Color.customBackground)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CREATE ROOM POSITION")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("ROOM POSITION CREATED")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white),
                    message: Text("Do you want to save the room position?"),
                    primaryButton: .default(Text("SAVE ROOM POSITION")) {
                        saveConversionGlobalLocal(response.1, floor.floorURL, floor)
                        showAlert = false
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
        }
    }
}

func orderBySimilarity(node: SCNNode, listOfNodes: [SCNNode]) -> [SCNNode] {
    print(node.scale)
    var result: [(SCNNode, Float)] = []
    for n in listOfNodes {
        result.append((n, simd_fast_distance(n.simdScale, node.simdScale)))
    }
    return result.sorted(by: { a, b in a.1 < b.1 }).map { $0.0 }
}


struct RoomPositionView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        let floor = firstBuildingIndex.floors.first!
        let room = floor.rooms.first!
        
        return RoomPositionView(floor: floor, room: room)
    }
}

