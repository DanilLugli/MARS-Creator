import SwiftUI
import Foundation

struct BuildingsView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText = ""
    @State private var selectedBuilding: UUID = UUID()
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationStack {
            VStack {
                
                if buildingsModel.getBuildings().isEmpty {
                    VStack {
                        Text("Add Building with + icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    VStack{
                        
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .padding()
                        
                        
                        ScrollView {
                            LazyVStack(spacing: 50) {
                                ForEach(filteredBuildings, id: \.id) { building in
                                    NavigationLink(destination: BuildingView(building: building)) {
                                        DefaultCardView(name: building.name, date: building.lastUpdate).padding()
                                    }
                                }
                            }
                        }.padding(.top, 15)
                    }
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
                                .font(.system(size: 22))
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

struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        
        return BuildingsView().environmentObject(buildingModel)
    }
}
