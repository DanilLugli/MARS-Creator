import SwiftUI
import Foundation
import Combine

struct RoomView: View {
    
    @EnvironmentObject var buildingModel: BuildingModel
    @Environment(\.dismiss) private var dismiss // Environment dismiss for navigation back
    
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @ObservedObject var building: Building
    
    @State private var newRoomName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedConnection: TransitionZone? = nil
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var selectedTab: Int = 0
    @State private var selectedFileURL: URL?
    @State private var selectedImageURL: URL?
    
    @State private var isRenameSheetPresented = false
    @State private var isNavigationScanRoomActive = false
    @State private var isConnectionAdjacentFloor = false
    @State private var isRoomPlanimetryUploadPicker = false
    @State private var isConnectionSameFloor = false
    @State private var isErrorAlertPresented = false
    @State private var isOptionsSheetPresented = false
    @State private var isUpdateOpenView = false
    @State private var isCreateRoomPosition = false
    @State private var isCreateManualRoomPosition = false
    @State private var isReferenceMarkerUploadPicker = false
    @State private var isColorPickerPopoverPresented = false
    
    @State private var showUpdateOptionsAlert = false
    @State private var showUpdateAlert = false
    @State private var showDeleteConfirmation = false
    
    @State private var selectedColor = Color(
        .sRGB,
        red: 0.98,
        green: 0.9,
        blue: 0.2)
    
    @State private var errorMessage: String = ""
    @State private var alertMessage = ""
    @State private var searchText: String = ""
    
    @State var mapRoomPositionView = SCNViewMapContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 4) {
                    Text(building.name)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                    Text(floor.name)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                    Text(room.name)
                }
                .font(.system(size: 14))
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                
                TabView(selection: $selectedTab) {
                    RoomPlanimetryView(room: room)
                        .tabItem {
                            Label("Room Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)
                    
                    RoomPositionTabView(room: room, floor: floor)
                        .tabItem {
                            Label("Room Position", systemImage: "sum")
                        }
                        .tag(1)
                    
                    MarkerView(room: room)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Marker", systemImage: "photo")
                        }
                        .tag(2)
                    
                    TransitionZoneTabView(room: room)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Transition Zones", systemImage: "mappin.and.ellipse")
                        }
                        .tag(4)
                    
                    ConnectionsTabView(room: room, floor: floor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Connections", systemImage: "arrow.left.arrow.right")
                        }
                        .tag(3)
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)      }
        .navigationTitle("Room")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab == 0 {
                    Menu {
                        Button(action: {
                            isRenameSheetPresented = true
                        }) {
                            Label("Rename Room", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            isOptionsSheetPresented = true
                        }) {
                            Label("Create Planimetry", systemImage: "plus")
                        }.disabled(FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                        
                        
                        Button(action: {
                            alertMessage = "If you proceed with the update, the current floor plan will be deleted.\nThis action is irreversible, are you sure you want to continue?"
                            showUpdateAlert = true
                        }) {
                            Label("Update Planimetry", systemImage: "arrow.clockwise")
                        }.disabled(!FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                        
                        Divider()
                        
                        Button(action: {
                            isColorPickerPopoverPresented = true
                            //                                ColorPicker("Choose a color", selection: $selectedColor)
                            //                                    .padding()
                        }) {
                            Label("Change Room Color", systemImage: "paintpalette")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red) // Imposta l'icona in rosso
                                Text("Delete Room")
                                    .foregroundColor(.red) // Imposta il testo in rosso
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
                if selectedTab == 1 {
                    Menu {
                        Button(action: {
                            isRoomPlanimetryUploadPicker = true
                        }) {
                            Label("Create Room Position Automatic Mode", systemImage: "mappin.and.ellipse")
                        }.disabled(true)
                        
                        Button(action: {
                            isCreateRoomPosition = true
                            print("isCreateRoomPosition set to true") // Debug
                        }) {
                            Label("Create Room Position Association Mode", systemImage: "mappin")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            isCreateManualRoomPosition = true
                            print("isCreateManualRoomPosition set to true") // Debug
                        }) {
                            Label("Correct Room Position", systemImage: "mappin")
                        }
                        
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue, .blue)
                    }
                    
                    NavigationLink(
                        destination: RoomPositionView(floor: self.floor, room: self.room),
                        isActive: $isCreateRoomPosition,
                        label: {
                            EmptyView()
                        }
                    )
                    
                    NavigationLink(
                        destination: ManualRoomPositionView(floor: self.floor, room: self.room),
                        isActive: $isCreateManualRoomPosition,
                        label: {
                            EmptyView()
                        }
                    )
                }
                else if selectedTab == 2 {
                    Button(action: {
                        isReferenceMarkerUploadPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
                else if selectedTab == 3 {
                    ZStack {
                        Menu {
                            Button(action: {
                                isConnectionSameFloor = true
                            }) {
                                Label("Create Same Floor Connection", systemImage: "arrow.left.arrow.right")
                            }.disabled(true)
                            
                            Button(action: {
                                isConnectionAdjacentFloor = true
                            }) {
                                Label("Create Adjacent Floors Connection", systemImage: "arrow.up.arrow.down")
                            }
                            
                            // Navigazione verso una terza vista
                            Button(action: {
                                // Azione per la connessione ascensore, se necessario
                            }) {
                                Label("Create Elevator Connection", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                            }.disabled(true)
                            
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                    
                    // Posiziona i NavigationLink fuori dal Menu e ZStack
                    NavigationLink(
                        destination: AddStairsConnectionView(building: building, initialSelectedFloor: floor, initialSelectedRoom: room),
                        isActive: $isConnectionAdjacentFloor,
                        label: {
                            EmptyView()
                        }
                    )
                    
                    NavigationLink(
                        destination: AddSameConnectionView(building: building, initialSelectedFloor: floor, initialSelectedRoom: room),
                        isActive: $isConnectionSameFloor,
                        label: {
                            EmptyView()
                        }
                    )
                }
                else if selectedTab == 4 {
                    HStack{
                        NavigationLink(destination: AddTransitionZoneView(floor: floor, room: room)) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isColorPickerPopoverPresented) {
            ZStack {
                // Rettangolo che riempie l'intera sheet
                Color.customBackground
                    .edgesIgnoringSafeArea(.all)  // Assicura che lo sfondo copra tutta l'area
                
                VStack {
                    Text("Change Room Color")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    ColorPicker("Choose a color", selection: $selectedColor)
                        .padding()
                        .foregroundColor(.white)
                        .bold()
                        .onChange(of: selectedColor) {
                            let uiColor = UIColor(selectedColor)
                            room.color = uiColor.withAlphaComponent(0.3)
                            
                            var floorRooms: [Room] = []
                            floor.rooms.forEach { room in
                                floorRooms.append(room)
                            }
                            
                            floor.planimetryRooms.handler.loadRoomsMaps(floor: floor, rooms: floorRooms, borders: true)
                        }
                }
                .padding()
            }
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isReferenceMarkerUploadPicker) {
            FilePickerView { url in
                selectedFileURL = url
                
                // Definisci il file manager
                let fileManager = FileManager.default
                
                // Estrai l'estensione del file per determinare se è un'immagine
                let fileExtension = url.pathExtension.lowercased()
                let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
                
                // Se l'URL selezionato è un'immagine, aggiungi un nuovo ReferenceMarker
                if imageExtensions.contains(fileExtension) {
                    // Definisci il percorso di destinazione per l'immagine
                    let destinationURL = room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("\(url.lastPathComponent)")
                    
                    do {
                        // Crea la directory "ReferenceMarker" se non esiste
                        let referenceMarkerDirectory = room.roomURL.appendingPathComponent("ReferenceMarker")
                        if !fileManager.fileExists(atPath: referenceMarkerDirectory.path) {
                            try fileManager.createDirectory(at: referenceMarkerDirectory, withIntermediateDirectories: true, attributes: nil)
                        }
                        
                        try fileManager.copyItem(at: url, to: destinationURL)
                        
                        //                            let referenceMarker = ReferenceMarker(
                        //                                imagePath: destinationURL,
                        //                                imageName: url.lastPathComponent,
                        //                                coordinates: Coordinates(latitude: 0.0, longitude: 0.0), // Aggiungi le coordinate reali se disponibili
                        //                                rmUML: URLComponents(string: "")
                        //                            )
                        //
                        //                            // Aggiungi il nuovo ReferenceMarker all'array della stanza
                        //                            room.addReferenceMarker(referenceMarker: referenceMarker)
                        // Assuming the image file name is the same as the marker name
                        
                        print("Image added successfully to ReferenceMarkers: \(destinationURL)")
                        
                    } catch {
                        // In caso di errore, aggiorna lo stato e mostra l'alert
                        errorMessage = "Failed to save the image: \(error.localizedDescription)"
                        isErrorAlertPresented = true
                    }
                }
            }
        }
        .confirmationDialog("How do you want to create the \(room.name) planimetry?", isPresented: $isOptionsSheetPresented, titleVisibility: .visible) {
            
            Button("Create With AR") {
                let fileManager = FileManager.default
                let filePath = room.roomURL
                    .appendingPathComponent("MapUsdz")
                    .appendingPathComponent("\(room.name).usdz")
                
                do {
                    try fileManager.removeItem(at: filePath)
                    print("File eliminato correttamente")
                } catch {
                    print("Errore durante l'eliminazione del file: \(error)")
                }
                
                self.isOptionsSheetPresented = false
                self.isNavigationScanRoomActive = true
            }
            .font(.system(size: 20))
            .bold()
            
            Button("Update From File") {
                // Chiudi il dialogo
                self.isOptionsSheetPresented = false
                
                // Apri la Sheet del file picker dopo aver chiuso quella corrente
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isRoomPlanimetryUploadPicker = true
                }
            }
            .font(.system(size: 20))
            .bold()
            
            Button("Cancel", role: .cancel) {
                // Azione di annullamento, facoltativa
            }
        }
        .confirmationDialog("Are you sure to delete Room?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                floor.deleteRoom(room: room)
                dismiss() // Navigate back after deletion
                print("Room deleted and navigating back")
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert(isPresented: $isErrorAlertPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Rename Room", isPresented: $isRenameSheetPresented, actions: {
            TextField("New Room Name", text: $newRoomName)
                .padding()
            
            Button("SAVE", action: {
                if !newRoomName.isEmpty {
                    do {
                        try BuildingModel.getInstance().getBuilding(building)?.getFloor(floor)?.renameRoom(floor: floor, room: room, newName: newRoomName)
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
            Text("Enter a new name for the Room.")
        })
        .alert(isPresented: $isErrorAlertPresented) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        
        NavigationLink(
            destination: ScanningView(namedUrl: room),
            isActive: $isNavigationScanRoomActive,
            label: {
                EmptyView()
            }
        )
    }
}



struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        return RoomView(room: room, floor: floor, building: building).environmentObject(buildingModel)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

enum TabIdentifier: String, Hashable {
    case room = "Room"
    case roomPosition = "RoomPosition"
    case referenceMarker = "ReferenceMarker"
    case transitionZone = "TransitionZone"
    case connection = "Connections"
}
