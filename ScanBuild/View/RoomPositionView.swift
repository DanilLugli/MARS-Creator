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

    @State var originalRoomNodes: [String] = [] // Nuovo stato per memorizzare i nodi originali

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
                        Picker(selection: $selectedFloorNodeName, label: Text("")) {
                            ForEach(floor.sceneObjects ?? [], id: \.self) { node in
                                Text(node.name ?? "Unnamed").tag(node.name ?? "")
                            }
                        }.onAppear {
                            print("Floor Scene Objects onAppear: \(floor.sceneObjects?.compactMap { $0.name } ?? [])")
                            if let firstNodeName = floor.sceneObjects?.first?.name {
                                selectedFloorNodeName = firstNodeName
                            }
                        }
                        .onChange(of: selectedFloorNodeName) { newValue in
                            print("New NAME NODE: \(newValue)")
                            floor.planimetry.changeColorOfNode(nodeName: newValue, color: UIColor.red)
                            
                            let firstLetter = String(newValue.prefix(3)) // Prende le prime tre lettere
                            
                            selectedFloorNode = floor.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })

                            // Filtra i nodi della stanza in base al prefisso del nodo di floor
                            filterRoomNodes(byPrefix: firstLetter)
                        }
                    }
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                VStack{
                    HStack {
                        Text("Room: \(room.name)").bold().font(.title3).foregroundColor(.white)
                    }
                    

                    ZStack {
                        room.planimetry
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }.onAppear{
                        originalRoomNodes = room.sceneObjects?.compactMap { $0.name ?? "" } ?? []
                        roomNodes = originalRoomNodes // Imposta i nodi originali alla comparsa
                    }
                    
                    HStack {
                        Picker("Choose Room Node", selection: $selectedRoomNodeName) {
                            Text("Choose Room Node")
                            ForEach(roomNodes, id: \.self) { nodeName in
                                Text(nodeName).tag(nodeName)
                            }
                        }.onAppear {
                            let sceneObjectsWithNames = room.sceneObjects?.compactMap { $0.name }
                            print("Room Scene Objects with names: \(sceneObjectsWithNames)")
                            if let firstRoomNodeSelected = sceneObjectsWithNames?.first {
                                selectedRoomNodeName = firstRoomNodeSelected
                            }
                        }.onChange(of: selectedRoomNodeName){ newValue in
                            print("CHANGE COLOR")
                            
                            room.planimetry.changeColorOfNode(nodeName: selectedRoomNodeName, color: UIColor.red)
                            
                            selectedRoomNode = room.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })
                            print("SELEZIONATO: \(String(describing: selectedRoomNode))")
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

                            floor.planimetry.drawContent(borders: true)
                            room.planimetry.drawContent(borders: true)

                            print(_selectedLocalNode)
                            print(_selectedGlobalNode)
                            print(selectedMap.lastPathComponent)
                            print(matchingNodesForAPI)

                            resetRoomNodes()
                        }.frame(width: 160, height: 50)
                            .foregroundStyle(.white)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(20)
                            .bold()
                    }
                    
                    if matchingNodesForAPI.count >= 3{
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
                            
                                responseFromServer = true
                                showAlert = true
                            }
                        }.frame(width: 160, height: 50)
                            .foregroundColor(.white)
                            .background(Color(red: 62/255, green: 206/255, blue: 76/255).opacity(0.3))
                            .cornerRadius(20)
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

    // Funzione per filtrare i nodi di room in base al prefisso
    func filterRoomNodes(byPrefix prefix: String) {
        roomNodes = originalRoomNodes.filter { $0.hasPrefix(prefix) }
    }
    
    // Funzione per ripristinare tutti i nodi di room
    func resetRoomNodes() {
        roomNodes = originalRoomNodes
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

