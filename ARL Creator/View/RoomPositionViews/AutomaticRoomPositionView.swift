
import Foundation
import SwiftUI
import SceneKit
import AlertToast

struct AutomaticRoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State var selectedRoomNode: SCNNode?
    @State var selectedFloorNode: SCNNode?
    
    @State var selectedRoomNodeName: String = ""
    @State var selectedFloorNodeName: String = ""
    
    var floorView: SCNViewContainer = SCNViewContainer(empty: true)
    var roomView: SCNViewContainer = SCNViewContainer(empty: true)
    var roomsMaps: [URL]?
    
    @State var floorNodes: [String] = []
    @State var roomNodes: [SCNNode] = []
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    @State private var showAddRoomPositionToast = false
    @State private var showErrorHTTPResponseToast = false
    @State private var showLoadingPositionToast = false
    @State private var showAlert = false
    @State private var showSheet = false
    @State private var showInfoPositionAlert = false
    @State private var isChangingColors = false
    
    
    @State private var selectedMap: URL = URL(fileURLWithPath: "")
    @State private var filteredLocalMaps: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    
    
    @State var responseFromServer = false {
        didSet {
            if responseFromServer {
                showSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showAlert = false
                    responseFromServer = false
                    showLoadingPositionToast = false
                }
            }
        }
    }
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["": ""])
    @State var apiResponseCode = ""
    @State var matchingNodesForAPI: [(SCNNode, SCNNode)] = []
    
    @State var originalRoomNodes: [SCNNode] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                ConnectedDotsView(
                    labels: ["1° Association", "2° Association", "3° Association", "Confirm"],
                    progress: min(matchingNodesForAPI.count + 1, 4)
                )
                
                VStack{
                    VStack {
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            Text("Floor: \(floor.name)")
                                .bold()
                                .font(.title3)
                                .foregroundColor(Color.customBackground)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        
                    }
                    
                    ZStack {
                        floorView
                            .border(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.gray, radius: 3)
                            .padding(.horizontal, 20)
                    }.onAppear{
                        floorView.loadFloorPlanimetry(borders: false, floor: floor)
                    }
                       
                    HStack {
                        Picker(selection: $selectedFloorNodeName, label: Text("")) {
                            ForEach(groupNodesByType(nodes: floor.sceneObjects ?? []), id: \.key) { type, nodes in
                                Section(header: Text(type.capitalized).bold()) {  // Sezione per ogni tipologia
                                    ForEach(nodes, id: \.self) { node in
                                        Text(node.name ?? "Unnamed").tag(node.name ?? "").bold()
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let firstNodeName = floor.sceneObjects?.first?.name {
                                selectedFloorNodeName = firstNodeName
                            }
                        }
                        .onChange(of: selectedFloorNodeName) { oldValue, newValue in
                            guard !isChangingColors else { return }
                            if oldValue != newValue {
                                floorView.resetColorNode()
                            }

                            selectedFloorNode = floor.sceneObjects?.first(where: { $0.name == newValue })
                            floorView.changeColorOfNode(nodeName: newValue, color: UIColor.green)

                            if let selectedFloorNode = selectedFloorNode {
                                let selectedType = extractType(from: selectedFloorNode.name ?? "")
                                if let firstMatchingNode = room.sceneObjects?.first(where: { extractType(from: $0.name ?? "") == selectedType }) {
                                    selectedRoomNodeName = firstMatchingNode.name ?? ""
                                    selectedRoomNode = firstMatchingNode
                                    roomView.changeColorOfNode(nodeName: selectedRoomNodeName, color: UIColor.green)
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                
                Divider()
                    .frame(height: 2)
                    .background(Color.white)
                
                VStack{
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                            Text("Room: \(room.name)").bold().font(.title3).foregroundColor(Color.customBackground)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .padding(.horizontal, 20)
                        
                        
                    }
                    
                    ZStack {
                        roomView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .shadow(color: Color.gray, radius: 3)
                    }.onAppear{
                        roomView.loadRoomPlanimetry(room: room, borders: false)
                    }
                    
                    HStack {
                        Picker(selection: $selectedRoomNodeName, label: Text("")) {
                            ForEach(groupNodesByType(nodes: room.sceneObjects ?? []), id: \.key) { type, nodes in
                                Section(header: Text(type.capitalized).bold()) { // Crea una sezione per ogni tipologia
                                    ForEach(nodes, id: \.self) { node in
                                        Text(node.name ?? "Unnamed").tag(node.name ?? "").bold()
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if let firstNodeName = room.sceneObjects?.first?.name {
                                selectedRoomNodeName = firstNodeName
                                selectedRoomNode = room.sceneObjects?.first
                            }
                        }
                        .onChange(of: selectedRoomNodeName) { oldValue, newValue in
                            guard !isChangingColors else { return }
                            if oldValue != newValue {
                                roomView.resetColorNode()
                            }

                            selectedRoomNode = room.sceneObjects?.first(where: { node in
                                node.name == newValue
                            })
                            roomView.changeColorOfNode(nodeName: newValue, color: UIColor.green)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                
                HStack {
                    if matchingNodesForAPI.count <= 2 {
                        Button("Confirm Relation") {
                           
                            if let _selectedLocalNode = selectedRoomNode,
                               let _selectedGlobalNode = selectedFloorNode {
                                
                                matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))

                                selectedRoomNode = nil
                                selectedFloorNode = nil
                                
                                selectedFloorNodeName = ""
                                selectedRoomNodeName = ""
                                
                                roomView.resetColorNode()
                                floorView.resetColorNode()
                            }
                            
                            if matchingNodesForAPI.count == 3{
                                let colors: [UIColor] = [.red, .green, .blue]
                                isChangingColors = true 

                                for (index, nodePair) in matchingNodesForAPI.prefix(3).enumerated() {
                                    let (roomNode, floorNode) = nodePair
                                    let color = colors[index]

                                    roomView.changeColorOfNode(nodeName: roomNode.name ?? "", color: color)

                                    floorView.changeColorOfNode(nodeName: floorNode.name ?? "", color: color)
                                }
                            }
                        }
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .frame(width: 160, height: 50)
                        .foregroundStyle(.white)
                        .background((selectedRoomNode != nil && selectedFloorNode != nil) ? Color.blue.opacity(0.4) : Color.gray.opacity(0.6))
                        .cornerRadius(30)
                        .bold()
                        
                    }

                    
                    if matchingNodesForAPI.count >= 3 {
                        Button("Calculate Position") {
                            Task {
                                showLoadingPositionToast = true

                                do {
                                    response = try await fetchAPIConversionLocalGlobal(localName: room.name, nodesList: matchingNodesForAPI)

                                    if let httpResponse = response.0 {
                                        let statusCode = httpResponse.statusCode
                                        print("Status code: \(statusCode)")
                                        
                                        if statusCode >= 400 {
                                            showLoadingPositionToast = false
                                            showErrorHTTPResponseToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                dismiss()
                                            }
                                            print("Error status code: \(statusCode)")
                                            return
                                        }
                                        print("Response JSON: \(response.1)")
                                    } else {
                                        print("Error: \(response.1)")
                                        showErrorHTTPResponseToast = true
                                        return
                                    }
                                    
                                    // Se la risposta è valida, esegue il codice successivo
                                    print("Test aass. Matrix 1:")
                                    print(floor.associationMatrix.keys)

                                    responseFromServer = true

                                    saveConversionGlobalLocal(response.1, floor.floorURL, floor)
                                    
                                    floor.updateAssociationMatrixInJSON(for: room.name, fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                    
                                    let fileManager = FileManager.default
                                    let associationMatrixURL = floor.floorURL.appendingPathComponent("\(floor.floorURL.lastPathComponent).json")
                                    if fileManager.fileExists(atPath: associationMatrixURL.path),
                                       let loadedMatrix = loadRoomPositionFromJson(from: associationMatrixURL, for: floor) {
                                        floor._associationMatrix = loadedMatrix
                                    } else {
                                        print("Failed to load RotoTraslationMatrix from JSON file for floor \(floor.floorURL.lastPathComponent)")
                                    }

                                    room.hasPosition = true
                                    
                                    floor.planimetryRooms.handler.loadRoomsMaps(
                                        floor: floor,
                                        rooms: floor.rooms
                                    )
                                    
                                    print("Test aass. Matrix 2:")
                                    print(floor.associationMatrix.keys)
                                    
                                    roomView.resetColorNode()
                                    floorView.resetColorNode()

                                    showLoadingPositionToast = false
                                    showInfoPositionAlert = true
                                    
                                } catch {
                                    showLoadingPositionToast = false
                                }                            }
                        }.font(.system(size: 16, weight: .bold, design: .default))
                            .frame(width: 160, height: 50)
                            .foregroundColor(.white)
                            .background(Color(red: 62/255, green: 206/255, blue: 76/255))
                            .cornerRadius(30)
                            .bold()
                    }
                }
            }
            .onDisappear{
                floorView.resetColorNode()
                roomView.resetColorNode()
            }
            .background(Color.customBackground)
            .navigationTitle("Create Room Position")
            .alert(isPresented: $showInfoPositionAlert) {
                Alert(
                    title: Text("ATTENTION"),
                    message: Text("If the room position is tilted, repeat the calculation using the association method."),
                    dismissButton: .default(Text("OK")) {
                        showAddRoomPositionToast = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            dismiss()
                        }
                    }
                )
            }
            .toast(isPresenting: $showAddRoomPositionToast) {
                AlertToast(type: .complete(Color.green), title: "Room position Created Successfully")
            }
            .toast(isPresenting: $showErrorHTTPResponseToast) {
                AlertToast(type: .error(Color.red), title: "Error Response Creation Position")
            }
            .toast(isPresenting: $showLoadingPositionToast) {
                AlertToast(type: .loading, title: "Creating Position")
            }
        }
    }
    
    
    func filterRoomNodes_Original(byTypeOf selectedFloorNode: SCNNode) {
        var selectedType = extractType(from: selectedFloorNode.name ?? "")
        
        roomNodes = originalRoomNodes.filter { node in
            let nodeType = extractType(from: node.name ?? "")
            return nodeType == selectedType
        }
        
        if let firstNodeName = roomNodes.first?.name {
            selectedRoomNodeName = firstNodeName
        } else {
            selectedRoomNodeName = ""
            selectedRoomNode = nil
        }
    }
    
    func resetRoomNodes() {
        roomNodes = originalRoomNodes
    }
    
    func groupNodesByType(nodes: [SCNNode]) -> [(key: String, value: [SCNNode])] {
        let groupedDict = Dictionary(grouping: nodes) { extractType(from: $0.name ?? "Unknown") }
        return groupedDict.sorted { $0.key < $1.key }
    }
    
    func filterRoomNodes(byTypeOf selectedFloorNode: SCNNode) {
        // 1) Ricavo il tipo del nodo selezionato
        let selectedType = extractType(from: selectedFloorNode.name ?? "")

        // 2) Non filtrare più: mantieni tutti i nodi
        roomNodes = originalRoomNodes

        // 3) Trova il primo nodo che ha lo stesso tipo
        if let firstMatchingNode = roomNodes.first(where: {
            let nodeType = extractType(from: $0.name ?? "")
            return nodeType == selectedType
        }) {
            // Se esiste, lo selezioniamo
            selectedRoomNodeName = firstMatchingNode.name ?? ""
            // Qui, se serve, imposta anche `selectedRoomNode = firstMatchingNode`
        } else {
            // Altrimenti, nessun nodo di questo tipo
            selectedRoomNodeName = ""
            selectedRoomNode = nil
        }
    }
    
    
//    func resetColorOfNode(nodeName: String) {
//        // Trova tutti i nodi aggiunti con il nome "__selected__"
//        if let nodes = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
//            n.name == "__selected__"
//        }) {
//            // Rimuove i nodi copiati dalla scena
//            for node in nodes {
//                node.removeFromParentNode()
//            }
//        }
//        
//        // Ripristina il nodo originale
//        if let originalNode = scnView.scene?.rootNode.childNodes(passingTest: { n, _ in
//            n.name == nodeName
//        }).first {
//            if let originalMaterial = originalNode.geometry?.firstMaterial {
//                originalMaterial.diffuse.contents = UIColor.white // Colore originale o predefinito
//            }
//        }
//    }
    
    func calculateVolume(of node: SCNNode) -> Float {
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        let length = max.x - min.x
        let width = max.y - min.y
        let height = max.z - min.z
        return length * width * height
    }
    
    func extractType(from nodeName: String) -> String {
        // Estrae tutti i caratteri dall'inizio fino al primo numero
        let name = nodeName.lowercased()
        var type = ""
        for character in name {
            if character.isNumber {
                break
            }
            type.append(character)
        }
        return type.isEmpty ? "unknown" : type
    }
    

    
    func sortSceneObjects(nodes: [SCNNode]) -> [SCNNode] {
        
        let typeOrder = ["wall", "storage", "chair", "table", "window", "door"]
        
        return nodes.sorted { (node1, node2) -> Bool in
            let type1 = extractType(from: node1.name ?? "")
            let type2 = extractType(from: node2.name ?? "")
            
            let typeIndex1 = typeOrder.firstIndex(of: type1) ?? typeOrder.count
            let typeIndex2 = typeOrder.firstIndex(of: type2) ?? typeOrder.count
            
            if typeIndex1 != typeIndex2 {
                return typeIndex1 < typeIndex2
            } else {
                let size1 = calculateVolume(of: node1)
                let size2 = calculateVolume(of: node2)
                return size1 > size2
            }
        }
    }
}

struct RoomPositionView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        let floor = firstBuildingIndex.floors.first!
        let room = floor.rooms.first!
        
        return AutomaticRoomPositionView(floor: floor, room: room)
    }
}
