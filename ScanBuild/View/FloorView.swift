import SwiftUI
import Foundation

struct FloorView: View {
    
    
    @State var showConnection: Bool = false
    @State var indexbuilding : Int
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(showConnection ? "\(buildingsModel.getBuildings()[indexbuilding].name)>Connections" : "\(buildingsModel.getBuildings()[indexbuilding].name)>Floors")
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
                
                if buildingsModel.getBuildings()[indexbuilding].floors.isEmpty {
                    VStack {
                        Text("Add Floor to \(buildingsModel.getBuildings()[indexbuilding].name) with + icon")
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
                                        
                                        FloorCardView(name: floor.name, date: floor.date)
                     
                                    }
                                    
                                }
                            }else{
                                ForEach( buildingsModel.getBuildings()[indexbuilding].connections.listConnections()){ floorBridge in
                                    
                                    NavigationLink(destination: AddBuildingView()) {
                                        
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
                Text(buildingsModel.getBuildings()[indexbuilding].name)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: AddBuildingView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white, .blue, .blue)
                        
                    }
                    Button(action: {
                        // Azione per il pulsante "info.circle"
                        print("Info button tapped")
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
            }
        }
    }
    
    
    var filteredFloors: [Floor] {
        if searchText.isEmpty {
            return buildingsModel.getBuildings()[indexbuilding].floors
        } else {
            return buildingsModel.getBuildings()[indexbuilding].floors.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct FloorCardView: View {
    var name: String
    var date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text(date)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 330, height: 80)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.leading, .trailing], 10)
    }
}

struct ConnectionCardView: View {
    
    var floorBridge: FloorBridge
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(floorBridge.description)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
        }
        .padding()
        .frame(width: 330, height: 80)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.leading, .trailing], 10)
    }
}

struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        // Creazione di un'istanza di BuildingModel solo per l'anteprima
        let building = Building(name: "Example Building", floors: [], date: "01-01-2022", fileURL: URL(fileURLWithPath: ""))
        let buildingModel = BuildingModel.getInstance()
        buildingModel.addBuilding(building: building)
        
        return FloorView(indexbuilding: 0)
            .environmentObject(buildingModel) // Passare l'istanza di buildingModel all'ambiente della vista di anteprima
    }
}
