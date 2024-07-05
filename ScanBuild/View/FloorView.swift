import SwiftUI
import Foundation

struct FloorView: View {
    
    
    @State var showConnection: Bool = false
    @State var buildingId : UUID
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText: String = ""
    
    var body: some View {
        
        
        NavigationStack {
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
                                    NavigationLink(destination: AddBuildingView()) {
                                        
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
            
            //ZStack() {
            HStack{
                Button(action: {
                    // Azione del pulsante per impostare showConnection a false
                    showConnection = false
                }) {
                    Text("FLOORS")
                        .fontWeight(.heavy)
                        .font(.system(size: 22))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            Group {
                                if !showConnection{
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Azione del pulsante per impostare showConnection a true
                    showConnection = true
                }) {
                    Text("CONNECTION")
                        .fontWeight(.heavy)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(Group {
                            if showConnection{
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
                            }
                        })
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(height: 60)
            .background(Color.blue)
            .cornerRadius(10)
            .padding([.leading, .trailing], 16)
            // }
            
        }
        .foregroundColor(.white)
        .background(Color.customBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\( buildingsModel.getBuildingById(buildingId)?.name ?? "Unknown")")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if !showConnection{
                        NavigationLink(destination: AddBuildingView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                            
                        }
                        Menu {
                            Button(action: {
                                // Azione per il pulsante "Rename"
                                print("Rename button tapped")
                            }) {
                                Text("Rename")
                                Image(systemName: "pencil")
                            }

                            Button(action: {
                                // Azione per il pulsante "Upload Building to Server"
                                print("Upload Building to Server button tapped")
                            }) {
                                Text("Upload Building to Server")
                                Image(systemName: "icloud.and.arrow.up")
                            }

                            Button(action: {
                                // Azione per il pulsante "Info"
                                print("Info button tapped")
                            }) {
                                Text("Info")
                                Image(systemName: "info.circle")
                            }
                            
                            Button(action: {
                                // Azione per il pulsante "Delete Building"
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
                    else{
                        NavigationLink(destination: AddConnection(selectedBuilding: buildingId)) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                            
                        }
                        Menu {
                            Button(action: {
                                // Azione per il pulsante "Rename"
                                print("Rename button tapped")
                            }) {
                                Text("Rename Connection")
                                Image(systemName: "pencil")
                            }

                            Button(action: {
                                // Azione per il pulsante "Info"
                                print("Info button tapped")
                            }) {
                                Text("Info")
                                Image(systemName: "info.circle")
                            }
                            
                            Button(action: {
                                // Azione per il pulsante "Delete Building"
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
                    }

                }
                
            }
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
