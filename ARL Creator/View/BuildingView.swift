import SwiftUI
import AlertToast
import Foundation

struct BuildingView: View {
    
    @ObservedObject var building : Building
    
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    
    @State private var showDeleteConfirmation = false
    @State private var isAddFloorSheetPresented = false
    @State private var newFloorName = ""
    
    @State private var showAddFloorToast = false
    @State private var showDeleteBuildingToast = false
    @State private var showRenameBuildingToast = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    
                    HStack(spacing: 4) {
                        Text(building.name)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                        Text("Floors")
                    }
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    
                    if building.floors.isEmpty {
                        VStack {
                            HStack(spacing: 4) {
                                Text("Add Floor with")
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                    } else {
                        
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 13)
                            .frame(maxWidth: .infinity)
                        
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
        .navigationTitle("\(building.name)")
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
                    showRenameBuildingToast = true
                }
            })
            
            Button("Cancel", role: .cancel, action: {
                isRenameSheetPresented = false
            })
        }, message: {
            Text("Enter a new name for the building.")
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        isAddFloorSheetPresented = true
                    }) {
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
                showDeleteBuildingToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
                print("Building eliminato")
            }
            
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this building? This action cannot be undone.")
        }
        .sheet(isPresented: $isAddFloorSheetPresented) {
            addFloorSheet
        }
        .toast(isPresenting: $showAddFloorToast) {
            AlertToast(type: .complete(Color.green), title: "Floor added")
        }
        .toast(isPresenting: $showDeleteBuildingToast) {
            AlertToast(type: .complete(Color.green), title: "Building deleted successfully")
        }
        .toast(isPresenting: $showRenameBuildingToast){
            AlertToast(
                type: .regular,
                title: "Building Renamed",
                subTitle: "Building Renamed in \(building.name)"
            )
        }
    }
    
    var filteredFloors: [Floor] {
        if searchText.isEmpty {
            return building.floors
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return building.floors
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    // Custom sheet content for adding a new floor
    private var addFloorSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text("New Floor")
                    .font(.title)
                    .foregroundColor(.customBackground)
                    .bold()
            }
            
            TextField("Floor Name", text: $newFloorName)
                .padding()
                .foregroundColor(.customBackground)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            Button(action: {
                addNewFloor()
                isAddFloorSheetPresented = false
            }) {
                Text("Create Floor")
                    .font(.headline)
                    .bold()
                    .padding()
                    .background(newFloorName.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            .disabled(newFloorName.isEmpty)
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    // Function to handle adding a new floor
    private func addNewFloor() {
        guard !newFloorName.isEmpty else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        _ = dateFormatter.string(from: Date())
        
        let newFloor = Floor(
            _name: newFloorName,
            _lastUpdate: Date(),
            _planimetry: SCNViewContainer(),
            _planimetryRooms: SCNViewMapContainer(),
            _associationMatrix: [String : RotoTraslationMatrix](),
            _rooms: [],
            _sceneObjects: nil,
            _scene: nil,
            _floorURL: building.buildingURL.appendingPathComponent("\(newFloorName)")
        )
        print("DEBUGG: \(newFloor.floorURL)")
        building.addFloor(floor: newFloor)
        newFloorName = ""
        showAddFloorToast = true
    }
}

struct BuildingView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuilding = buildingModel.initTryData()
        
        return BuildingView(building: firstBuilding)
    }
}
