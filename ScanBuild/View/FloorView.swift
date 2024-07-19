import SwiftUI
import Foundation

struct FloorView: View {
    
    @State var building : Building
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("\(building.name) > Floors")
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
                    
                    if building.floors.isEmpty {
                        VStack {
                            Text("Add Floor to \(building.name) with + icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 25) {
                                ForEach(filteredFloors, id: \.id) { floor in
                                    NavigationLink(destination: RoomView( floor: floor, buildingName: building.name)) {
                                        DefaultCardView(name: floor.name, date: floor.lastUpdate)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                HStack {
                    Button(action: {
                        // Azione del pulsante per aggiungere un piano
                    }) {
                        Text("ADD FLOOR")
                            .fontWeight(.heavy)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 170, height: 60)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding([.trailing], 16)
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .principal) {
//                Text("\(building.name)")
//                    .font(.system(size: 26, weight: .heavy))
//                    .foregroundColor(.white)
//            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: AddFloorView(building: building)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                    Menu {
                        Button(action: {
                            // Azione per il pulsante "Rename"
                            isRenameSheetPresented = true
                        }) {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(action: {
                            print("Upload Building to Server button tapped")
                        }) {
                            Label("Upload Building to Server", systemImage: "icloud.and.arrow.up")
                        }
                        Button(action: {
                            print("Info button tapped")
                        }) {
                            Label("Info", systemImage: "info.circle")
                        }
                        Button(action: {
                            print("Delete Building button tapped")
                        }) {
                            Label("Delete Building", systemImage: "trash")
                                .foregroundColor(.red)
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
                        building.name = newBuildingName
                        newBuildingName = ""
                        isRenameSheetPresented = false
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
    
    var filteredFloors: [Floor] {
        if searchText.isEmpty {
            return building.floors
        } else {
            return building.floors.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuilding = buildingModel.initTryData()
        
        return FloorView(building: firstBuilding)
    }
}
