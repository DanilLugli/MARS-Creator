import SwiftUI
import Foundation

struct MarkerView: View {
    
    @State var room: Room
    var building: Building
    var floor: Floor
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("\(building.name) > \(floor.name) > \(room.name) > \(tabTitle)")
                        .font(.system(size: 14))
                        .fontWeight(.heavy)
                    Spacer()
                    Spacer()
                    TextField("Search", text: $searchText)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                        .frame(width: 180)
                    
                    TabView(selection: $selectedTab) {
                        VStack {
                            Text("PLANIMETRY").foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Planimetry", systemImage: "map")
                        }
                        .tag(0)
                        
                        VStack {
                            if room.referenceMarkers.isEmpty {
                                VStack {
                                    Text("Add Marker to \(room.name) with + icon")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 25) {
                                        ForEach(filteredMarker, id: \.id) { marker in
                                            Button(action: {
                                                selectedMarker = marker
                                            }) {
                                                DefaultCardView(name: marker.imageName, date: Date())
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
                        
                        VStack {
                            Text("TRANSITION ZONE").foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("TransitionZone", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        }
                        .tag(2)
                        
                        VStack {
                            if room.getConnections().isEmpty {
                                VStack {
                                    Text("No connections available for \(room.name)")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 25) {
                                        ForEach(room.getConnections(), id: \.id) { connection in
                                            DefaultCardView(name: connection.name, date: Date())
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Connection", systemImage: "link")
                        }
                        .tag(3)
                    }
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
            .navigationTitle(tabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {
//                        Text("CIAO")
//                    }) {
//                        Image(systemName: "arrow.left")
//                    }
////                }
//                ToolbarItem(placement: .principal) {
//                    Text(tabTitle)
//                        .font(.system(size: 26, weight: .heavy))
//                        .foregroundColor(.white)
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if selectedTab == 1 {
                            NavigationLink(destination: Text("Add Marker View")) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                            Menu {
                                Button(action: {
                                    // Azione per il pulsante "Rename"
                                    isRenameSheetPresented = true
                                }) {
                                    Text("Rename")
                                    Image(systemName: "pencil")
                                }
                                Button(action: {
                                    print("Upload Building to Server button tapped")
                                }) {
                                    Text("Upload Building to Server")
                                    Image(systemName: "icloud.and.arrow.up")
                                }
                                Button(action: {
                                    print("Info button tapped")
                                }) {
                                    Text("Info")
                                    Image(systemName: "info.circle")
                                }
                                Button(action: {
                                    print("Delete Building button tapped")
                                }) {
                                    Text("Delete")
                                    Image(systemName: "trash")
                                }
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 26))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                        } else if selectedTab == 2 {
                            NavigationLink(destination: Text("Add Transition Zone View")) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                        } else if selectedTab == 3 {
                            //TODO: aggiornare chiamata AddConnectionView
                            NavigationLink(destination: AddConnectionView(selectedBuilding: building, selectedFloor: floor, selectedRoom: room)) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
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
                    Text("Details for \(marker.imageName)")
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    Text("Rename Marker")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .foregroundColor(.white)
                    TextField("New Marker Name", text: $newBuildingName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    Spacer()
                    HStack {
                        Button(action: {
                            if !newBuildingName.isEmpty {
                                // Salva il nuovo nome del marker
                            }
                        }) {
                            Text("SAVE")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                        Button(action: {
                            //TODO: deletereferenceMarker()
                            selectedMarker = nil
                        }) {
                            Text("DELETE")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
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
