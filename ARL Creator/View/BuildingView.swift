import SwiftUI
import Foundation

struct BuildingView: View {
    
    @ObservedObject var building : Building
    
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    
                    Text("\(building.name) > Floors")
                        .font(.system(size: 14))
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                    
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
                        
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .padding()
                        
                        ScrollView {
                            LazyVStack(spacing: 50) {
                                ForEach(filteredFloors, id: \.id) { floor in
                                    NavigationLink(destination: FloorView(floor: floor, building: building)) {
                                        DefaultCardView(name: floor.name, date: floor.lastUpdate).padding()
                                    }
                                }
                            }
                        }
                        .padding(.top, 15)
                    }
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationTitle("Building")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: AddFloorView(building: building)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                    Menu {
                        Button(action: {
                            isRenameSheetPresented = true
                        }) {
                            Label("Rename Building", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            print("Save Building to Server button tapped")
                        }) {
                            Label("Save Building to Server", systemImage: "icloud.and.arrow.up")
                        }.disabled(true)
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                            
                            print("Delete Building button tapped")
                            
                        }) {
                            Label("Delete Building", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
            }
        }
        .confirmationDialog("Confirm Deletion", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                BuildingModel.getInstance().deleteBuilding(building: building)
                print("Building eliminato")
            }
            
            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("Are you sure you want to delete this building? This action cannot be undone.")
        }
        .alert("Rename Building", isPresented: $isRenameSheetPresented, actions: {
            TextField("New Building Name", text: $newBuildingName)
                .padding()

            Button("SAVE", action: {
                if !newBuildingName.isEmpty {
                    do {
                        try BuildingModel.getInstance().renameBuilding(building: building, newName: newBuildingName)
                    } catch {
                        print("Errore durante la rinomina: \(error.localizedDescription)")
                    }
                    isRenameSheetPresented = false
                }
            })
            
            Button("Cancel", role: .cancel, action: {
                isRenameSheetPresented = false
            })
        }, message: {
            Text("Enter a new name for the building.")
        })

    }
    
    var filteredFloors: [Floor] {
        if searchText.isEmpty {
            building.floors.forEach{ building in
                building.debugPrint()
            }
            return building.floors
        } else {
            return building.floors.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}



struct BuildingView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuilding = buildingModel.initTryData()
        
        return BuildingView(building: firstBuilding)
    }
}
