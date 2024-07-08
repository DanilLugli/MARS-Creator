import SwiftUI
import Foundation

struct FloorView: View {
    
    
    @State var showConnection: Bool = false
    @State var buildingId : UUID
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    
    var body: some View {
        
        
        NavigationStack {
            VStack{
                VStack {
                    Text(showConnection ? "\(buildingsModel.getBuildingById(buildingId)?.name ?? "Unknown") > Connections" : "\( buildingsModel.getBuildingById(buildingId)?.name ?? "Unknown") > Floors")
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
                    
                    if buildingsModel.getFloors(byBuildingId: buildingId).isEmpty {
                        VStack {
                            Text("Add Floor to \( buildingsModel.getBuildingById(buildingId)?.name ?? "Unknown") with + icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 25) {
                                if !showConnection{
                                    ForEach(filteredFloors) { floor in
                                        NavigationLink(destination: RoomView(floorId: floor.id)) {
                                            DefaultCardView(name: floor.name, date: floor.date)
                                        }
                                        
                                    }
                                }else{
                                    ForEach( buildingsModel.listConnections(buildingId: buildingId)){ floorBridge in NavigationLink(destination: AddBuildingView()) {
                                        ConnectionCardView(floorBridge: floorBridge)
                                    }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                HStack {
                    
                    Button(action: {
                        showConnection = false
                    }) {
                        Text("FLOORS")
                            .fontWeight(.heavy)
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                Group {
                                    if !showConnection {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
                                    }
                                }
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 170, height: 60)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding([.trailing], 16)
                    
                    Button(action: {
                        // Azione del pulsante per impostare showConnection a true
                        showConnection = true
                    }) {
                        Text("CONNECTION")
                            .fontWeight(.heavy)
                            .font(.system(size: 20))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                Group {
                                    if showConnection {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
                                    }
                                }
                            )
                            .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 170, height: 60)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding([.trailing], 12)
                }
            }.background(Color.customBackground).foregroundColor(.white)
        }

        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(buildingsModel.getBuildingById(buildingId)?.name ?? "Unknown")")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if !showConnection {
                        NavigationLink(destination: AddFloorView(selectedBuilding: buildingId)) {
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
                                Text("Delete Building")
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    } else {
                        NavigationLink(destination: AddConnectionView(selectedBuilding: buildingId)) {
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
                                Image(systemName: "trash")
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
                        buildingsModel.renameBuilding(id: buildingId, newName: newBuildingName)
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
            return buildingsModel.getFloors(byBuildingId: buildingId)
        } else {
            return buildingsModel.getFloors(byBuildingId: buildingId).filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}


struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingId = buildingModel.initTryData()
        
        return FloorView(buildingId: firstBuildingId).environmentObject(buildingModel) // Passare l'istanza di buildingModel all'ambiente della vista di anteprima
    }
}
