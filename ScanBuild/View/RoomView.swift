import SwiftUI
import Foundation

struct RoomView: View {

    @ObservedObject var floor: Floor
    var building: Building
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedTab: Int = 0
    @State private var animateRooms: Bool = false
    @State private var newRoom: Room? = nil
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(selectedTab == 1 ? "\(building.name) > \(floor.name) > Planimetry" : (selectedTab == 2 ? "\(building.name) > \(floor.name) > Matrix" : "\(building.name) > \(floor.name) > Rooms"))
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                Spacer()
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .padding(.top, 90)
                    .frame(maxWidth: .infinity)
                    .padding()
                
                TabView(selection: $selectedTab) {
                    FloorPlanimetryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Planimetry", systemImage: "map.fill")
                        }
                        .tag(1)
                    
                    //TODO: Perchè non va la VIew esterna ?????
                    VStack {
                        if floor.rooms.isEmpty {
                            VStack {
                                Text("Add Room to \(floor.name) with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 50) {
                                    ForEach(floor.rooms, id: \.id) { room in
                                        NavigationLink(destination: MarkerView(room: room, building: building,   floor: floor)) {
                                            DefaultCardView(name: room.name, date: room.lastUpdate).padding()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Rooms", systemImage: "list.dash")
                        }
                        .tag(0)
                    
                    ListMatrixView().frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Matrix", systemImage: "sum")
                        }
                        .tag(2)
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(selectedTab == 0 ? "\(floor.name)" : (selectedTab == 1 ? "PLANIMETRY" : "MATRIX"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if selectedTab == 0 {
                        NavigationLink(destination: AddRoomView(floor: floor), isActive: $isNavigationActive) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                                .onTapGesture {
                                    let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                                    self.newRoom = newRoom
                                    self.isNavigationActive = true
                                }
                        }
                        Menu {
                            Button(action: {
                                print("Rename button tapped")
                            }) {
                                Text("Rename Connection")
                                Image(systemName: "pencil")
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
                                Text("Delete Connection")
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    } else {
                        Menu {
                            Button(action: {
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
                                Text("Delete Building")
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isRenameSheetPresented) {
            VStack {
                Text("Rename Building")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                TextField("New Building Name", text: $newBuildingName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer()
                Button(action: {
                    if !newBuildingName.isEmpty {
                        // Salva il nuovo nome dell'edificio
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
            }
            .padding()
            .background(Color.customBackground.ignoresSafeArea())
        }
    }
    
    var filteredRooms: [Room] {
        if searchText.isEmpty {
            return floor.rooms
        } else {
            return floor.rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        
        return RoomView(floor: floor, building: building)
    }
}
