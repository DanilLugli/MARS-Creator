import SwiftUI
import Foundation

struct HomeView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText = ""
    @State private var selectedBuilding: UUID = UUID()
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Spacer()
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .frame(width: 180)
                Spacer()
                
                if buildingsModel.getBuildings().isEmpty {
                    VStack {
                        Text("Add Building with + icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    VStack(alignment: .center ){
                        //Color.customBackground.ignoresSafeArea() // Imposta lo sfondo blu
                        ForEach(filteredBuildings) { building in
                            NavigationLink(destination: FloorView(buildingId: building.id)) {
                                DefaultCardView(name: building.name, date: building.date)
                            }
                            
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BUILDINGS")
                        .font(.system(size: 26))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: AddBuildingView()) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                        
                    }
                }
            }
        }
    }
    
    var filteredBuildings: [Building] {
        if searchText.isEmpty {
            return buildingsModel.getBuildings()
        } else {
            return buildingsModel.getBuildings().filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        //let _ = buildingModel.initTryData()
        
        HomeView().environmentObject(buildingModel)
    }
}

//extension Color {
//    static let customBackground = Color(red: 0x1A / 255, green: 0x37 / 255, blue: 0x61 / 255)
//}
