import Foundation
import SwiftUI
import SceneKit

struct RoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State var selectedRoomNode: SCNNode?
    @State var selectedFloorNode: SCNNode?
    
    @State var selectedRoomNodeName: String = ""
    @State var selectedFloorNodeName: String = ""
    
    var roomView: SCNViewContainer = SCNViewContainer()
    var roomsMaps: [URL]?
    
    @State var floorNodes: [String] = []
    @State var roomNodes: [String] = []
    
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

    var body: some View {
        NavigationStack {
            VStack {
                ConnectedDotsView(
                    labels: ["1° Association", "2° Association", "3° Association", "Confirm"],
                    progress: min(matchingNodesForAPI.count + 1, 4)
                )
                
                VStack{
                    VStack {
                        Text("Floor: \(floor.name)").bold().font(.title3).foregroundColor(.white)
                    }
                    
                    ZStack {
                        floor.planimetry
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }
                       
                    HStack {
                        Picker("Choose Floor Node", selection: $selectedFloorNodeName) {
                            ForEach(floor.sceneObjects ?? [], id: \.self) { node in
                                Text(node.name ?? "Unnamed").tag(node.name ?? "")
                            }
                        }
                        .onAppear {
                            print("Floor Scene Objects onAppear: \(floor.sceneObjects?.compactMap { $0.name } ?? [])")
                            if let firstNodeName = floor.sceneObjects?.first?.name {
                                selectedFloorNodeName = firstNodeName
                            }
                        }
                        .onChange(of: selectedFloorNodeName) {newValue in
                            print("New NAME NODE: \(newValue)")
                            floor.planimetry.changeColorOfNode(nodeName: newValue, color: UIColor.red)
                            
                            let firstLetter = String(newValue.prefix(4))
                            
//                            roomNodes = roomView.scnView.scene?.rootNode.childNodes(passingTest: {
//                                n, _ in n.name != nil && n.name!.starts(with: firstLetter) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
//                            })
//                            .sorted(by: { a, b in
//                                let sizeA = SCNVector3(
//                                    a.boundingBox.max.x - a.boundingBox.min.x,
//                                    a.boundingBox.max.y - a.boundingBox.min.y,
//                                    a.boundingBox.max.z - a.boundingBox.min.z
//                                )
//                                
//                                let sizeB = SCNVector3(
//                                    b.boundingBox.max.x - b.boundingBox.min.x,
//                                    b.boundingBox.max.y - b.boundingBox.min.y,
//                                    b.boundingBox.max.z - b.boundingBox.min.z
//                                )
//                                return sizeA.x > sizeB.x
//                            })
//                            .map { node in node.name ?? "nil" } ?? []
//                            
                            selectedFloorNode = floor.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })
                        }
                    }
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                VStack{
                    HStack {
                        Text("Room: \(room.name)").bold().font(.title3).foregroundColor(.white)
                    }
                    

                    ZStack {
                        roomView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }.onAppear{
                        //roomView.loadRoomPlanimetry(room: room, borders: true)
                        roomView.loadRoomPlanimetry(room: room, borders: false)
                    }
                    
                    
                    HStack {
                        Picker("Choose Room Node", selection: $selectedRoomNodeName) {
                            Text("Choose Room Node")
                            //ForEach(roomNodes, id: \.self) { Text($0) }
                            ForEach(roomNodes, id: \.self) { node in
                                //print("Node ID: \(node.name)") // Debug output
                                Text(node).tag(node)
                            }
                        }.onChange(of: selectedRoomNodeName){
                            
                            roomView.changeColorOfNode(nodeName: selectedRoomNodeName, color: UIColor.green)
                            
                            selectedRoomNode = roomView.scnView.scene?.rootNode.childNodes(passingTest: {
                                n, _ in n.name != nil && n.name! == selectedRoomNodeName
                            }).first
                        }
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
    
    func getSceneNodeNames(from sceneObjects: [SCNNode]?) -> [String] {
        // Verifica se sceneObjects non è nil e lo trasforma in un array di nomi, altrimenti ritorna un array vuoto
        return sceneObjects?.compactMap { $0.name ?? "Unnamed Node" } ?? []
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

//
//struct RoomPositionView_Preview: PreviewProvider {
//    static var previews: some View {
//        let buildingModel = BuildingModel.getInstance()
//        let firstBuildingIndex = buildingModel.initTryData()
//        let floor = firstBuildingIndex.floors.first!
//        let room = floor.rooms.first!
//        
//        return RoomPositionView(floor: floor, room: room)
//    }
//}

