import SwiftUI
import Foundation

struct MarkerView: View {
    
    //TODO: Se non c'è la planimetry, aggiungere immagine + per fare la SCAN
    
    @ObservedObject var room: Room
    var building: Building
    var floor: Floor
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedTab: Int = 0
    @State private var isNavigationActive = false
    var mapView = SCNViewContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("\(building.name) > \(floor.name) > \(room.name)")
                        .font(.system(size: 14))
                        .fontWeight(.heavy)
                    
//                    TextField("Search", text: $searchText)
//                        .padding(7)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(8)
//                        .padding(.horizontal, 10)
//                    //.padding(.top, 90)
//                        .frame(maxWidth: .infinity)
//                        .padding()
                    
                    TabView(selection: $selectedTab) {
                        VStack {
                            if isDirectoryEmpty(url: room.roomURL.appendingPathComponent("MapUsdz")){
                                Text("Add Planimetry with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            } else {
                                VStack {
                                    mapView
                                        .border(Color.white).cornerRadius(10).padding().shadow(color: Color.gray, radius: 3)
                                }
                                .onAppear {
                                    mapView.loadRoomMaps(name: room.name, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)
                        
                        VStack {
                            if room.referenceMarkers.isEmpty {
                                VStack {
                                    Text("No Marker in \(room.name)")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 50) {
                                        ForEach(filteredMarker, id: \.id) { marker in
                                            Button(action: {
                                                selectedMarker = marker
                                            }) {
                                                MarkerCardView(name: marker.imageName, rowSize: 1).padding()
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Marker", systemImage: "mappin.and.ellipse")
                        }
                        .tag(1)
                        
                        
                        VStack{
                            if floor.associationMatrix.isEmpty {
                                VStack {
                                    Text("Add Matrix with + icon")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 50) {
                                        ForEach(floor.associationMatrix.keys.sorted(), id: \.self) { key in
                                            if let matrix = floor.associationMatrix[key]{
                                                DefaultCardView(name: matrix.name, date: Date(), rowSize: 1, isSelected: false)
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Matrix", systemImage: "sum")
                        }
                        .tag(3)
                        
                        VStack {
                            Text("No connections available for \(room.name)")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("TransitionZone", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        }
                        .tag(2)
                        
                        //                        VStack {
                        //                            if room.getConnections().isEmpty {
                        //                                VStack {
                        //                                    Text("No connections available for \(room.name)")
                        //                                        .foregroundColor(.gray)
                        //                                        .font(.headline)
                        //                                        .padding()
                        //                                }
                        //                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        //                                .background(Color.customBackground)
                        //                            } else {
                        //                                ScrollView {
                        //                                    LazyVStack(spacing: 50) {
                        //                                        ForEach(room.getConnections(), id: \.id) { connection in
                        //                                            DefaultCardView(name: connection.name, date: Date()).padding()
                        //                                        }
                        //                                    }
                        //                                }
                        //                                .padding()
                        //                            }
                        //                        }
                        //                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        //                        .background(Color.customBackground)
                        //                        .tabItem {
                        //                            Label("Connection", systemImage: "link")
                        //                        }
                        //                        .tag(3)
                    }
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
            .foregroundColor(.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ROOM")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        
                        if selectedTab == 0 {
                            //TODO: aggiornare chiamata AddConnectionView
                            NavigationLink(destination: ScanningView(namedUrl: room)) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                        }else if selectedTab == 2{
                            NavigationLink(destination: AddConnectionView(selectedBuilding: building)) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                        } else if selectedTab == 3{
                            NavigationLink(destination: MatrixView(floor: floor, room: room), isActive: $isNavigationActive) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                                    .onTapGesture {
                                        //                                    let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                                        //                                    self.newRoom = newRoom
                                        self.isNavigationActive = true
                                    }
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedMarker) { marker in
                VStack {
                    Text("Marker Details")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .foregroundColor(.white)
                    selectedMarker?.image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    Text("Position Marker")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .foregroundColor(.white)
                    mapView.border(Color.white).cornerRadius(10).padding().shadow(color: Color.gray, radius: 3)
                    Spacer()
                    
                }
                .padding()
                .background(Color.customBackground.ignoresSafeArea())
            }
        }
    }
    
    var tabTitle: String {
        switch selectedTab {
        case 0: return "Planimentry"
        case 1: return "Markers"
        case 2: return "Transition Zone"
        case 3: return "Connection"
        default: return ""
        }
    }
    
    var filteredMarker: [ReferenceMarker] {
        if searchText.isEmpty {
            return room.referenceMarkers
        } else {
            return room.referenceMarkers.filter { $0.imageName.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func isDirectoryEmpty(url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            return contents.isEmpty
        } catch {
            print("Error checking directory contents: \(error)")
            return true
        }
    }
    
    struct MarkerView_Previews: PreviewProvider {
        static var previews: some View {
            let buildingModel = BuildingModel.getInstance()
            let building = buildingModel.initTryData()
            let floor = building.floors.first!
            let room = floor.rooms.first!
            return MarkerView(room: room, building: building, floor: floor)
        }
    }
    
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

