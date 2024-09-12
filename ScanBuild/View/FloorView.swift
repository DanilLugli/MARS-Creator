import SwiftUI
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
    @State private var animateRooms: Bool = false
    @State private var newRoom: Room? = nil
    
    @State private var selectedFileURL: URL?
    @State private var showFloorMap: Bool = false
    
    @State private var isNavigationActive = false
    @State private var isFloorPlanimetryUploadPicker = false
    @State private var isRenameSheetPresented = false
    @State private var isErrorUpdateAlertPresented = false
    @State private var isOptionsSheetPresented = false
    
    @State private var showUpdateOptionsAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showUpdateAlert = false
    
    @State private var alertMessage = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Text("\(building.name) > \(floor.name)")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                
                
                TabView(selection: $selectedTab) {
                    
                    VStack {
                        
                        Toggle(isOn: $showFloorMap) {
                            Text("Show Rooms")
                                .font(.system(size: 20)).bold()
                        }.toggleStyle(SwitchToggleStyle()).padding()
                        
                        if floor.planimetry == nil {
                            Text("Add Planimetry with + icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        }
                        else {
                            VStack {
                                ZStack {
                                    if showFloorMap{
                                        floor.planimetryRooms
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                    } else {
                                        floor.planimetry
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                    }
                                }
                            }
                            .onAppear {
                                var roomURLs: [URL] = []
                                
//                                floor.rooms.forEach { room in
//                                    roomURLs.append(room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
//                                }
//                                
//                                mapPositionView.handler.loadRoomMaps(
//                                    floor: floor,
//                                    roomURLs: roomURLs,
//                                    borders: true
//                                )
                                
//                                mapView.loadFloorPlanimetry(
//                                    borders: true,
//                                    usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
//                                )
                                
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground)
                    .tabItem {
                        Label("Floor Planimetry", systemImage: "map.fill")
                    }
                    .tag(0)
                    
                    VStack {
                        
                        if floor.rooms.isEmpty {
                            VStack {
                                Text("Add Room to \(floor.name) with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            }
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
                                    ForEach(floor.rooms, id: \.id) { room in
                                        NavigationLink(destination: RoomView(room: room, floor: floor, building: building )) {
                                            let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                            RoomCardView(name: room.name, date: room.lastUpdate, position: isSelected, color: room.color, rowSize: 1, isSelected: false).padding()
                                        }
                                    }
                                }
                            }.onAppear {
                                // Stampa di debug
                                print("PRINT DEBUG ROOM")
                                floor.rooms.forEach { room in
                                    room.debugPrintRoom() // Stampa i dati delle stanze
                                }
                            }
                            .padding(.top, 15)
                        }
                    }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FLOOR").font(.system(size: 26, weight: .heavy)).foregroundColor(.white)
            }
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
                            
                            Button(action: {
                                
                                self.isOptionsSheetPresented = true
                                
                            }) {
                                Label("Create Planimetry", systemImage: "plus")
                            }.disabled(FileManager.default.fileExists(atPath: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz").path))

                            
                            Button(action: {
                                alertMessage = "If you proceed with the update:\n1. Current floor plan\n2. All rooms position\nWill be deleted.\nThis action is irreversible, are you sure you want to continue?"
                                showUpdateAlert = true
                            }) {
                                Label("Update Planimetry", systemImage: "arrow.clockwise")
                            }.disabled(!FileManager.default.fileExists(atPath: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz").path))
                            
                            
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
                        NavigationLink(destination: FloorScanningView(namedUrl: floor), isActive: $isNavigationActive) {
                            EmptyView()
                        }
                    }
                    else if selectedTab == 1 {
                        NavigationLink(destination: AddRoomView(floor: floor), isActive: $isNavigationActive) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                                .onTapGesture {
                                    let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                                    self.newRoom = newRoom
                                    self.isNavigationActive = true
                                }
                        }
                    }
                }
            }
        }

        .confirmationDialog("How do you want to create the \(floor.name) planimetry?", isPresented: $isOptionsSheetPresented, titleVisibility: .visible) {
            
            Button("Create With AR") {
                let fileManager = FileManager.default
                let filePath = floor.floorURL
                    .appendingPathComponent("MapUsdz")
                    .appendingPathComponent("\(floor.name).usdz")
                
                do {
                    try fileManager.removeItem(at: filePath)
                    print("File eliminato correttamente")
                } catch {
                    print("Errore durante l'eliminazione del file: \(error)")
                }
                
                // Chiudi il dialogo e avvia la navigazione
                self.isOptionsSheetPresented = false
                self.isNavigationActive = true
            }
            .font(.system(size: 20))
            .bold()
            
            Button("Update From File") {
                // Chiudi il dialogo
                self.isOptionsSheetPresented = false
                
                // Apri la Sheet del file picker dopo aver chiuso quella corrente
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isFloorPlanimetryUploadPicker = true
                }
            }
            .font(.system(size: 20))
            .bold()

            Button("Cancel", role: .cancel) {
                // Azione di annullamento, facoltativa
            }
        }
        .confirmationDialog("Are you sure to delete Floor?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                building.deleteFloor(floor: floor)
                print("Floor eliminato")
                //dismiss() // Chiude la vista corrente
            }
            
            Button("Cancel", role: .cancel) {
                //Optional
            }
        }
        .alert(isPresented: $isErrorUpdateAlertPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("OK")) {
                    // Azione quando si preme "OK"
                    isOptionsSheetPresented = true
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    // Azione quando si preme "Cancel" (chiude l'alert automaticamente)
                }
            )
        }
        .alert("Rename Floor", isPresented: $isRenameSheetPresented, actions: {
            TextField("New Floor Name", text: $newFloorName)
                .padding()
            
            Button("SAVE", action: {
                if !newFloorName.isEmpty {
                    do {
                        try BuildingModel.getInstance().getBuilding(building)?.renameFloor(floor: floor, newName: newFloorName)
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
            Text("Enter a new name for the Floor.")
        })
        .sheet(isPresented: $isFloorPlanimetryUploadPicker) {
            FilePickerView { url in
                selectedFileURL = url
                
                // Definisci il percorso di destinazione per il file selezionato
                let destinationURL = floor.floorURL
                    .appendingPathComponent("MapUsdz")
                    .appendingPathComponent("\(floor.name).usdz")
                
                // Crea la directory "MapUsdz" se non esiste già
                let fileManager = FileManager.default
                let mapUsdzDirectory = floor.floorURL.appendingPathComponent("MapUsdz")
                
                do {
                    // Crea la directory se non esiste
                    if !fileManager.fileExists(atPath: mapUsdzDirectory.path) {
                        try fileManager.createDirectory(at: mapUsdzDirectory, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    // Copia il file dal suo URL originale al nuovo percorso
                    try fileManager.copyItem(at: url, to: destinationURL)
                    print("File copied successfully to: \(destinationURL)")
                    
                } catch {
                    // In caso di errore, aggiorna lo stato e mostra l'alert
                    errorMessage = "Failed to save the file: \(error.localizedDescription)"
                    isErrorUpdateAlertPresented = true
                }
            }
        }
    }
    
    var filteredRooms: [Room] {
        if searchText.isEmpty {
            print("PRINT DEBUG ROOM")
            floor.rooms.forEach{ room in
                room.debugPrintRoom()
            }
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

