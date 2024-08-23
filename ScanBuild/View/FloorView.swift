import SwiftUI
import Foundation
import UIKit
import UniformTypeIdentifiers

struct FloorView: View {
    
    @EnvironmentObject var buildingModel: BuildingModel
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
    @State private var showDeleteConfirmation = false // Stato per mostrare l'alert
    @State private var showUpdateAlert = false

    @State private var alertMessage = ""
    @State private var errorMessage: String = ""
    
    var mapView = SCNViewContainer()
    var mapPositionView = SCNViewMapContainer()
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Text("\(building.name) > \(floor.name)")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                
                
                TabView(selection: $selectedTab) {
                    
                    VStack {
                        
                        Toggle(isOn: $showFloorMap) {
                            Text("Show Local Map")
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
                                        mapPositionView
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                    } else {
                                        mapView
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                    }
                                    
                                    VStack {
                                        HStack {
                                            Spacer() // Push buttons to the right
                                            if showFloorMap{
                                                HStack {
                                                    Button("+") {
                                                        mapView.zoomIn()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8)
                                                    
                                                    Button("-") {
                                                        mapView.zoomOut()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8).padding()
                                                }
                                                .padding()
                                            }else{
                                                HStack {
                                                    Button("+") {
                                                        mapPositionView.handler.zoomIn()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8)
                                                    
                                                    Button("-") {
                                                        mapPositionView.handler.zoomOut()
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .bold()
                                                    .background(Color.blue.opacity(0.4))
                                                    .cornerRadius(8).padding()
                                                }
                                                .padding()
                                            }
                                        }
                                        Spacer() // Push buttons to the top
                                    }
                                }
                            }
                            .onAppear {
                                // Definisci un array di URL
                                var roomURLs: [URL] = []
                                
                                floor.rooms.forEach { room in
                                    print(room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
                                    roomURLs.append(room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
                                }
                                
                                mapPositionView.handler.loadRoomMaps(
                                    floor: floor,
                                    roomURLs: roomURLs,
                                    borders: true
                                )
                                
                                mapPositionView.handler.changeColorOfNode(nodeName: "Bagno", color: UIColor.orange)
                                mapPositionView.handler.changeColorOfNode(nodeName: "Sala", color: UIColor.yellow)
                                
                                // Carica la mappa generale
                                mapView.loadFloorPlanimetry(
                                    borders: true,
                                    usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
                                )
                                
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
                                        NavigationLink(destination: RoomView(room: room, building: building, floor: floor)) {
                                            let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                            RoomCardView(name: room.name, date: room.lastUpdate, position: isSelected, rowSize: 1, isSelected: false).padding()
                                        }
                                    }
                                }
                            }
                            .padding()
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
                                
                                self.isNavigationActive = true
                                
                                   }) {
                                Label("Create Planimetry", systemImage: "plus")
                            }.disabled(FileManager.default.fileExists(atPath: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz").path))
                            
                            Button(action: {
                                isFloorPlanimetryUploadPicker = true
                            }) {
                                Label("Upload Planimetry from File", systemImage: "square.and.arrow.down")
                            }.disabled(FileManager.default.fileExists(atPath: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz").path))
                            
                            Divider()
                            
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
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                        NavigationLink(destination: ScanningView(namedUrl: floor), isActive: $isNavigationActive) {
                            EmptyView()
                        }
                    }
                    else if selectedTab == 1 {
                        NavigationLink(destination: AddRoomView(floor: floor), isActive: $isNavigationActive) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
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
                        try building.renameFloor(floor: floor, newName: newFloorName)
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
//        .sheet(isPresented: $isRenameSheetPresented) {
//            VStack {
//                Text("Rename Building")
//                    .font(.system(size: 22))
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 20)
//                    .foregroundColor(.white)
//                TextField("New Building Name", text: $newBuildingName)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
//                Spacer()
//                Button(action: {
//                    if !newBuildingName.isEmpty {
//                        do {
//                            try building.renameFloor(floor: floor, newName: newBuildingName)
//                            print("Floor rinominato correttamente a \(newBuildingName)")
//                        } catch {
//                            print("Errore durante la rinomina del floor: \(error.localizedDescription)")
//                        }
//                    }
//                }) {
//                    Text("SAVE")
//                        .font(.system(size: 22, weight: .heavy))
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 20)
//            }
//            .padding()
//            .background(Color.customBackground.ignoresSafeArea())
//        }
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
        .sheet(isPresented: $isOptionsSheetPresented) {
            VStack {
                Text("Choose an option")
                    .font(.system(size: 26))
                    .fontWeight(.bold)
                    .padding()

                Button(action: {
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
                    self.isOptionsSheetPresented = false
                    // Setta isNavigationActive su true
                    self.isNavigationActive = true
                    // Chiudi la Sheet

                }) {
                    Text("Create with AR")
                        .font(.system(size: 20))
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)

                Button(action: {
                    // Chiudi la Sheet delle opzioni
                    self.isOptionsSheetPresented = false
                    
                    // Apri la Sheet del file picker dopo aver chiuso quella corrente
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.isFloorPlanimetryUploadPicker = true
                    }

                }) {
                    Text("Update From File")
                        .font(.system(size: 20))
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
            }
            .padding()
        }.background(Color.customBackground)
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

