import SwiftUI
import Foundation

struct RoomView: View {
    
    @State var floor : Floor
    var buildingName: String
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedTab: Int = 0
    @State private var animateRooms: Bool = false
    
    var floorName: String {
        floor.name
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(selectedTab == 1 ? "\(buildingName) > \(floorName) > Planimetry" : "\(buildingName) > \(floorName) > Rooms")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
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
                    } .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                    .tabItem {
                        Label("Planimetry", systemImage: "map.fill")
                    }
                    .tag(1)
                    
                    
                    VStack {
                        if floor.rooms.isEmpty {
                            VStack {
                                Text("Add Room to \(floorName) with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 25) {
                                    ForEach(filteredRooms, id: \.id) { room in
                                        NavigationLink(destination: MarkerView(room: room, buildingName: buildingName, floorName: floorName)) {
                                            DefaultCardView(name: room.name, date: room.lastUpdate)}
                                    }
                                                        
                                                    }
                            }
                            .padding()
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.customBackground)
                    .tabItem {
                        Label("Rooms", systemImage: "list.dash")
                    }
                    .tag(0)
//                    .scaleEffect(animateRooms ? 1.1 : 1.0)
//                                        .animation(.easeInOut(duration: 0.2), value: animateRooms)
//                                        .onAppear {
//                                            animateRooms = true
//                                        }
//                                        .onDisappear {
//                                            animateRooms = false
//                                        }
//                        
                    }
                }
                .background(Color.customBackground)
                .foregroundColor(.white)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedTab == 0 ? "ROOMS" : "PLANIMETRY")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if selectedTab == 0 {
                            NavigationLink(destination: Text("Add Connection View")) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
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
                        .foregroundColor(.white) // Colore bianco
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
            
            return RoomView(floor: floor, buildingName: building.name)
        }
    }

