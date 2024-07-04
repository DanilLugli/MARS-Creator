import SwiftUI
import Foundation

struct HomeView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    
    @State private var searchText = ""
    @State private var selectedBuilding: Int = 0
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
                
                if buildingsModel.buildings.isEmpty {
                    VStack {
                        Text("Add Building with + icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground)
                } else {
                    ZStack {
                        Color.customBackground.ignoresSafeArea() // Imposta lo sfondo blu
                        List {
                            ForEach(Array(filteredBuildings.enumerated()), id: \.0) { index,building in
                                Button(action: {
                                    selectedBuilding = index
                                    isNavigationActive = true
                                }) {
                                    BuildingView(name: building.name, address: building.date)
                                }
                                .listRowBackground(Color.customBackground) // Imposta lo sfondo blu per ogni riga
                            }
                            .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                        NavigationLink(destination: FloorView(indexbuilding: selectedBuilding),
                                       isActive: $isNavigationActive) {
                            EmptyView()
                        }
                    }
                }
            }
            .foregroundColor(.white)
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
                        Button(action: {
                            // Azione per il pulsante "info.circle"
                            print("Info button tapped")
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                //.symbolWeight(self: .heavy)
                                .symbolRenderingMode(.palette)
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

struct BuildingView: View {
    var name: String
    var address: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text(address)
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


struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

extension Color {
    static let customBackground = Color(red: 0x1A / 255, green: 0x37 / 255, blue: 0x61 / 255)
}
