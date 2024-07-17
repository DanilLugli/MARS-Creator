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
                    .padding(.top, 90)
                    .frame(width: 180)
                Spacer()
                
                if buildingsModel.buildings.isEmpty {
                    VStack {
                        Text("Add Building with + icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 25) {
                            ForEach(filteredBuildings, id: \.id) { building in
                                NavigationLink(destination: FloorView(buildingId: building.id)) {
                                    DefaultCardView(name: building.name, date: building.lastUpdate)
                                }
                            }
                        }
                    }.padding(.top, 30)
                }
            }
            .foregroundColor(.white)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.customBackground)
            .edgesIgnoringSafeArea(.all)
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
            return buildingsModel.buildings
        } else {
            return buildingsModel.buildings.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        
        return HomeView().environmentObject(buildingModel)
    }
}
