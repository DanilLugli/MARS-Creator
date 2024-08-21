import Foundation
import SwiftUI
import SceneKit

struct RoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State var selectedLocalNodeName = ""
    @State var selectedGlobalNodeName = ""
    
    @State var selectedLocalNode: SCNNode?
    @State var selectedGlobalNode: SCNNode?
    
    var globalView: SCNViewContainer
    var localView: SCNViewContainer
    var localMaps: [URL]?
    
    @State var globalNodes: [String]
    @State var localNodes: [String]
    
    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = []
    
//    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = [
//        (SCNNode(), SCNNode()),
//        (SCNNode(), SCNNode())
//    ]
    
    @State var apiResponseCode = ""
    
    @State var responseFromServer = false {
        didSet {
            if responseFromServer {
                // showAlert = true
                showSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showAlert = false
                    responseFromServer = false
                }
            }
        }
    }
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["": ""])
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    
    @State private var mapName: String = ""
    
    @State private var selectedMap: URL = URL(fileURLWithPath: "")
    @State private var availableMaps: [String] = []
    @State private var filteredLocalMaps: [String] = []
    
    @State private var showAlert = false
    @State private var showSheet = false
    
    
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
    
    init(floor: Floor, room: Room) {
        self.floor = floor
        self.room = room
        
        globalView = SCNViewContainer()
        localView = SCNViewContainer()
        
        globalView.loadFloorPlanimetry(borders: false, usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz"))
        
        localView.loadRoomMaps(name: room.name, borders: false, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
        
        globalNodes = Array(Set(globalView
            .scnView
            .scene?
            .rootNode
            .childNodes(passingTest: {
                n, _ in n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Geom" &&
                String(n.name!.suffix(4)) != "_grp"
            }).compactMap { node in node.name } ?? []))
        
        if let nodes = localView.scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
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

            localNodes = uniqueNamesArray.sorted()

            print("Unique node names: \(localNodes)")
        } else {
            localNodes = []
        }
    }
    
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
                    globalView
                        .border(Color.white)
                        .cornerRadius(10)
                        .padding()
                        .shadow(color: Color.gray, radius: 3)
                    
                    VStack {
                        HStack {
                            Spacer() // Push buttons to the right
                            HStack {
                                Button("+") {
                                    globalView.zoomIn()
                                }
                                .buttonStyle(.bordered)
                                .bold()
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8)
                                
                                Button("-") {
                                    globalView.zoomOut()
                                }
                                .buttonStyle(.bordered)
                                .bold()
                                .background(Color.blue.opacity(0.4))
                                .cornerRadius(8).padding()
                            }
                            .padding()
                        }
                        Spacer() // Push buttons to the top
                    }
                }
                
                HStack {
                    Picker("Choose Floor Node", selection: $selectedGlobalNodeName) {
                        Text("Choose Floor Node")
                        ForEach(globalNodes, id: \.self) { Text($0) }
                    }.onChange(of: selectedGlobalNodeName, perform: { _ in
                        globalView.changeColorOfNode(nodeName: selectedGlobalNodeName, color: UIColor.green)
                        
                        let firstTwoLetters = String(selectedGlobalNodeName.prefix(4))
                        
                        localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n, _ in n.name != nil && n.name!.starts(with: firstTwoLetters) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: { a, b in a.scale.x > b.scale.x })
                        .map { node in node.name ?? "nil" } ?? []
                        
                        selectedGlobalNode = globalView.scnView.scene?.rootNode.childNodes(passingTest: { n, _ in n.name != nil && n.name! == selectedGlobalNodeName }).first
                    })
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                HStack {
                    Text("Room: \(room.name)").bold().font(.title3).foregroundColor(.white)
                }
                
                if room != nil {
                    ZStack {
                        localView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                        
                        VStack {
                            HStack {
                                Spacer() // Push buttons to the right
                                HStack {
                                    Button("+") {
                                        localView.zoomIn()
                                    }
                                    .buttonStyle(.bordered)
                                    .bold()
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8)
                                    
                                    Button("-") {
                                        localView.zoomOut()
                                    }
                                    .buttonStyle(.bordered)
                                    .bold()
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(8).padding()
                                }
                                .padding()
                            }
                            Spacer() // Push buttons to the top
                        }
                    }
                    
                    HStack {
                        Picker("Choose Room Node", selection: $selectedLocalNodeName) {
                            Text("Choose Room Node")
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
                        Button("Confirm Relation") {
                            matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))
                            
                            print(_selectedLocalNode)
                            print(_selectedGlobalNode)
                            print(selectedMap.lastPathComponent)
                            print(matchingNodesForAPI)
                            
                        }.buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4)
                            .cornerRadius(10))
                            .bold()
                    }
                    //                    Text("matched nodes: \(matchingNodesForAPI.count)").foregroundColor(.white)
                    if matchingNodesForAPI.count >= 3 {
                        Button("Create Matrix") {
                            Task {
                                response = try await fetchAPIConversionLocalGlobal(localName: room.name, nodesList: matchingNodesForAPI)
                                if let httpResponse = response.0 {
                                    print("Status code: \(httpResponse.statusCode)")
                                    print("Response JSON: \(response.1)")
                                } else {
                                    print("Error: \(response.1)")
                                }
                                
                                //                                let emptyMatrix = RotoTraslationMatrix(
                                //                                    name: selectedMap.deletingPathExtension().lastPathComponent,
                                //                                    translation: simd_float4x4(1),
                                //                                    r_Y: simd_float4x4(1)
                                //                                )
                                //                                floor.associationMatrix["\(selectedMap.deletingPathExtension().lastPathComponent)"] = emptyMatrix
                                print(selectedMap.lastPathComponent)
                                print(matchingNodesForAPI)
                                saveConversionGlobalLocal(response.1, floor.floorURL, floor.name)
                                responseFromServer = true
                                showSheet = true
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
                    title: Text("Matrix Created Correctly"),
                    message: nil
                )
            }
            .sheet(isPresented: $showSheet) {
                VStack{
                    Text("ROOM POSITION CREATED AND SAVED CORRECTLY").font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white).padding()
                    Spacer()
                    Button("SAVE ROOM POSITION") {
                        saveConversionGlobalLocal(response.1, floor.floorURL, floor.name)
                        
                        showSheet = false
                    }.buttonStyle(.bordered)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(8).padding()
                        .bold()
                        .padding()
                    
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground.ignoresSafeArea())
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

