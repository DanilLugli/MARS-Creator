import SwiftUI
import AlertToast
import Foundation

struct BuildingsView: View {
    
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    @State private var searchText = ""
    @State private var selectedBuilding: Building? = nil
    @State private var navigationPath = NavigationPath()
    
    @State private var isAddBuildingSheetPresented = false
    @State private var newBuildingName = ""
    
    @State private var showAddBuildingToast = false
   

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if buildingsModel.getBuildings().isEmpty {
                    VStack {
                        HStack(spacing: 4) {
                            Text("Add Building with")
                                .foregroundColor(.gray)
                                .font(.headline)
                            
                            Image(systemName: "plus.circle")
                                .foregroundColor(.gray)
                            
                            Text("icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                        .padding()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground.ignoresSafeArea())
                }
                else {
                    VStack {
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 13)
                            .frame(maxWidth: .infinity)
                        
                        ScrollView {
                            LazyVStack(spacing: 50) {
                                ForEach(filteredBuildings, id: \.id) { building in
                                    NavigationLink(destination: BuildingView(building: building)) {
                                        DefaultCardView(name: building.name, date: Date())
                                            .padding()
                                    }
                                }
                            }
                        }
                        .padding(.top, 15)
                    }
                }
            }
            .foregroundColor(.white)
            .background(Color.customBackground.ignoresSafeArea())
            .navigationTitle("Buildings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddBuildingSheetPresented = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
            }
            .sheet(isPresented: $isAddBuildingSheetPresented) {
                addBuildingSheet
            }
            .toast(isPresenting: $showAddBuildingToast) {
                AlertToast(type: .complete(Color.green), title: "Building added")
            }
        }
    }
    
    var filteredBuildings: [Building] {
        if searchText.isEmpty {
            return buildingsModel.getBuildings()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return buildingsModel.getBuildings()
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    // Custom sheet content
    private var addBuildingSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text("New Building")
                    .font(.title)
                    .foregroundColor(.customBackground)
                    .bold()
            }
            
            TextField("Building Name", text: $newBuildingName)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.customBackground)
                .cornerRadius(8)
                .padding(.horizontal)
            
            Button(action: {
                addNewBuilding()
                isAddBuildingSheetPresented = false
            }) {
                Text("Create")
                    .font(.headline)
                    .bold()
                    .padding()
//                    .background()
                    .foregroundColor(newBuildingName.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(30)
            }
            .disabled(newBuildingName.isEmpty)
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }

    private func addNewBuilding() {
        guard !newBuildingName.isEmpty else { return }
        
        let newBuilding = Building(name: newBuildingName, lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: "") )
        buildingsModel.addBuilding(building: newBuilding)
        newBuildingName = ""
        isAddBuildingSheetPresented = false
        showAddBuildingToast = true
        
    }
}

struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        
        return BuildingsView().environmentObject(buildingModel)
    }
}
