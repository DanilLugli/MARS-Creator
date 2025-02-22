import SwiftUI
import AlertToast
import SceneKit
import Foundation
import UIKit
import UniformTypeIdentifiers

struct FloorView: View {
    
    @EnvironmentObject var buildingModel : BuildingModel
    @ObservedObject var floor: Floor
    @ObservedObject var building: Building
    
    @State private var searchText: String = ""
    @State private var newFloorName: String = ""
    @State private var selectedTab: Int = 0
    @State private var newRoomName: String = ""
    
    @State private var selectedFileURL: URL?
    @State private var showFloorMap: Bool = false
    
    @State private var isScanningFloorPlanimetry = false
    @State private var isRoomSheetPresented = false
    @State private var isFloorPlanimetryUploadPicker = false
    @State private var isRenameSheetPresented = false
    @State private var isErrorUpdateAlertPresented = false
    @State private var isOptionsSheetPresented = false
    
    @State private var showUpdateOptionsAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showFloorUpdatePlanimetryAlert = false
    
    @State private var showAddRoomToast = false
    @State private var showDeleteFloorToast = false
    @State private var showRenameFloorToast = false
    
    
    @State private var alertMessage = ""
    @State private var errorMessage: String = ""
    
    
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        
        NavigationStack {
            VStack {
                
                HStack(spacing: 4) {
                    Text(building.name)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                    Text(floor.name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .font(.system(size: 14))
                .fontWeight(.heavy)
                
                TabView(selection: $selectedTab) {
                    FloorPlanimetryView(floor: floor, showFloorMap: $showFloorMap)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Floor Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)

                    RoomsListView(floor: floor, building: building, searchText: $searchText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Rooms", systemImage: "list.dash")
                        }
                        .tag(1)
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationTitle("Floor")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if selectedTab == 0 {
                        Menu {
                            Button(action: {
                                isRenameSheetPresented = true
                            }) {
                                Label("Rename Floor", systemImage: "pencil")
                            }
                            
                            Divider()
                            if FileManager.default.fileExists(atPath: floor.floorURL
                                .appendingPathComponent("MapUsdz")
                                .appendingPathComponent("\(floor.name).usdz")
                                .path) {
                                
                                // ✅ Se il file esiste → Mostra "Update Planimetry"
                                Button(action: {
                                    alertMessage = """
                                        Proceeding with this update will permanently delete:

                                        1. The current \(floor.name)'s planimetry
                                        2. All room positions  

                                        This action cannot be undone. Are you sure you want to continue?
                                        """
                                    showFloorUpdatePlanimetryAlert = true
                                }) {
                                    Label("Update Planimetry", systemImage: "arrow.clockwise")
                                }
                                
                            } else {
                                
                                // ✅ Se il file NON esiste → Mostra "Create Planimetry" con NavigationLink
                                NavigationLink(destination: FloorScanningView(floor: floor)) {
                                    Label("Create Planimetry", systemImage: "plus")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Floor")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                    else if selectedTab == 1 {
                        Button(action: {
                            isRoomSheetPresented = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                    else if selectedTab == 2 {
                        Button(action: {
                            isRoomSheetPresented = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                }
            }
        }
        .confirmationDialog("How do you want to create the \(floor.name) planimetry?", isPresented: $isOptionsSheetPresented, titleVisibility: .visible) {
            
            NavigationLink(destination: FloorScanningView(floor: floor)){
                Button("Create With AR") {
        
                    self.isOptionsSheetPresented = false
                    self.isScanningFloorPlanimetry = true

                }
                .font(.system(size: 20))
                .bold()
            }
            
            
//            Button("Update From File") {
//
//                self.isOptionsSheetPresented = false
//                
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                    self.isFloorPlanimetryUploadPicker = true
//                }
//            }
//            .font(.system(size: 20))
//            .bold()

            Button("Cancel", role: .cancel) {
            }
        }
        .confirmationDialog("Are you sure to delete Floor?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                building.deleteFloor(floor: floor)
                showDeleteFloorToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
                print("Floor eliminato")
            }
            
            Button("Cancel", role: .cancel) {
            }
        }
        .alert(isPresented: $isErrorUpdateAlertPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showFloorUpdatePlanimetryAlert) {
            Alert(
                title: Text("ATTENTION"),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("OK")) {
                    let fileManager = FileManager.default
                    let filePaths = [
                        floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz"),
                        floor.floorURL.appendingPathComponent("JsonParametric").appendingPathComponent("\(floor.name).json"),
                        floor.floorURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(floor.name).plist")
                    ]

                    do {
                        for filePath in filePaths {
                            try fileManager.removeItem(at: filePath)
                            print("File at \(filePath) eliminato correttamente")
                        }
                    } catch {
                        print("Errore durante l'eliminazione di un file: \(error)")
                    }

                    floor.associationMatrix = [:]
                    clearJSONFile(at: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                    floor.planimetryRooms = SCNViewMapContainer()
                    floor.scene = nil
                    floor.sceneObjects = []
                    
                    isOptionsSheetPresented = true
                },
                secondaryButton: .cancel(Text("Cancel")) {
                }
            )
        }
        .alert("Rename Floor", isPresented: $isRenameSheetPresented,
               actions: {
            TextField("New Floor Name", text: $newFloorName)
                .padding()
            
            Button("SAVE", action: {
                if !newFloorName.isEmpty {
                    Task {
                        do {
                            if (try await building.renameFloor(floor: floor, newName: newFloorName)) != false {
                                showRenameFloorToast = true
                            } else {
                                print("Errore durante la rinomina del piano.")
                            }
                        } catch {
                            print("Errore: \(error.localizedDescription)")
                            errorMessage = "Errore durante la rinomina del piano: \(error.localizedDescription)"
                            isErrorUpdateAlertPresented = true
                        }
                    }
                    isRenameSheetPresented = false
                }
            })
            
            Button("Cancel", role: .cancel, action: {
                isRenameSheetPresented = false
            })
        },
               message: {
            Text("Enter a new name for the Floor.")
        }
        )
        .sheet(isPresented: $isFloorPlanimetryUploadPicker) {
            FilePickerView { url in
                selectedFileURL = url
                print("DEBUG: File selezionato: \(url.path)")
                
                let destinationURL = floor.floorURL
                    .appendingPathComponent("MapUsdz")
                    .appendingPathComponent("\(floor.name).usdz")
                
                let fileManager = FileManager.default
                let mapUsdzDirectory = floor.floorURL.appendingPathComponent("MapUsdz")
                
                do {
                    if !fileManager.fileExists(atPath: mapUsdzDirectory.path) {
                        try fileManager.createDirectory(at: mapUsdzDirectory, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    try fileManager.copyItem(at: url, to: destinationURL)
                    print("File copied successfully to: \(destinationURL)")
                    floor.scene = try SCNScene(url: destinationURL)
                    
                } catch {
                    // In caso di errore, aggiorna lo stato e mostra l'alert
                    errorMessage = "Failed to save the file: \(error.localizedDescription)"
                    isErrorUpdateAlertPresented = true
                }
            }
        }
        .sheet(isPresented: $isRoomSheetPresented) {
            addRoomSheet
        }
        .toast(isPresenting: $showAddRoomToast) {
            AlertToast(type: .complete(Color.green), title: "Room added")
        }
        .toast(isPresenting: $showDeleteFloorToast) {
            AlertToast(type: .complete(Color.green), title: "Floor deleted successfully")
        }
        .toast(isPresenting: $showRenameFloorToast){
            AlertToast(
                type: .regular,
                title: "Floor Renamed",
                subTitle: "Floor Renamed in \(floor.name)"
            )
        }
    }
    
    private var addRoomSheet: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.viewfinder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                
                Text("New Room")
                    .font(.title)
                    .foregroundColor(.customBackground)
                    .bold()
            }
            
            TextField("Room Name", text: $newRoomName)
                .padding()
                .foregroundColor(.customBackground)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            Button(action: {
                addNewRoom()
                isRoomSheetPresented = false
                newRoomName = ""
            }) {
                Text("Create Room")
                    .font(.headline)
                    .bold()
                    .padding()
//                    .background()
                    .foregroundColor(newRoomName.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(30)
            }
            .disabled(newRoomName.isEmpty)
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func addNewRoom() {
        guard !newRoomName.isEmpty else { return }
        
        let newRoom = Room(
            _name: newRoomName,
            _lastUpdate: Date(),
            _planimetry: SCNViewContainer(),
            _referenceMarkers: [],
            _transitionZones: [],
            _scene: nil,
            _sceneObjects: [],
            _roomURL: floor.floorURL.appendingPathComponent("Rooms").appendingPathComponent(newRoomName),
            parentFloor: floor
        )
        print("DEBUG: ROOMURL -> \(newRoom.roomURL)")
        newRoom.planimetry.loadRoomPlanimetry(room: newRoom, borders: true)
        floor.addRoom(room: newRoom)
        
        showAddRoomToast = true
        newRoom.validateRoom()


        floor._associationMatrix[newRoom.name] = RoomPositionMatrix(name: newRoom.name, translation: matrix_identity_float4x4, r_Y: matrix_identity_float4x4)
        
        floor.addIdentityMatrixToJSON(to: floor.floorURL.appendingPathComponent("\(floor.name).json"), for: floor, roomName: newRoom.name)
        
    }
    
    var filteredRooms: [Room] {
        if searchText.isEmpty {
            return floor.rooms
        } else {
            return floor.rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct FloorView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        
        return FloorView(floor: floor, building: building)
    }
}
