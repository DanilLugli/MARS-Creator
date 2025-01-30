import SwiftUI
import AlertToast
import Foundation
import Combine

struct RoomView: View {
    
    @EnvironmentObject var buildingModel: BuildingModel
    @Environment(\.dismiss) private var dismiss
    
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
    @State private var showRoomUpdatePlanimetryAlert = false
    @State private var showDeleteConfirmation = false
    
    @State private var showAddRoomPlanimetryToast = false
    @State private var showDeleteRoomToast = false
    @State private var showRenameRoomToast = false

    @State private var selectedColor = Color(
        .sRGB,
        red: 0.98,
        green: 0.9,
        blue: 0.2)
    
    @State private var errorMessage: String = ""
    @State private var alertMessage = ""
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                headerView()
                
                TabView(selection: $selectedTab) {
                    RoomPlanimetryTabView(room: room)
                        .tabItem {
                            Label("Room Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)
                    
                    RoomPositionTabView(room: room, floor: floor)
                        .tabItem {
                            Label("Room Position", systemImage: "mappin.and.ellipse")
                        }
                        .tag(1)
                    
                    RoomMarkerTabView(room: room)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Marker", systemImage: "photo")
                        }
                        .tag(2)
                    
                    RoomConnectionsTabView(building: building, room: room, floor: floor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Connections", systemImage: "arrow.up.arrow.down")
                        }
                        .tag(3)
                    
//                    RoomTransitionZoneTabView(room: room)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(Color.customBackground)
//                        .tabItem {
//                            Label("Transition Zones", systemImage: "mappin.and.ellipse")
//                        }
//                        .tag(4)
                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationTitle("Room")
        .toolbar { toolbarContent() }
        .alert("ATTENTION", isPresented: $showRoomUpdatePlanimetryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("OK", role: .destructive) {
                isOptionsSheetPresented = true
            }
        } message: {
            Text(alertMessage)
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
                    showRenameRoomToast = true
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
        .sheet(isPresented: $isColorPickerPopoverPresented) {
            changeRoomColor
        }
        .sheet(isPresented: $isReferenceMarkerUploadPicker) {
            FilePickerView { url in
                selectedFileURL = url
                
                let fileManager = FileManager.default
                
                let fileExtension = url.pathExtension.lowercased()
                let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
                
                if imageExtensions.contains(fileExtension) {

                    let destinationURL = room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("\(url.lastPathComponent)")
                    
                    do {
                       
                        let referenceMarkerDirectory = room.roomURL.appendingPathComponent("ReferenceMarker")
                        if !fileManager.fileExists(atPath: referenceMarkerDirectory.path) {
                            try fileManager.createDirectory(at: referenceMarkerDirectory, withIntermediateDirectories: true, attributes: nil)
                        }
                        
                        try fileManager.copyItem(at: url, to: destinationURL)
                        
                        let referenceMarker = ReferenceMarker(
                            _imagePath: room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("\(url.lastPathComponent)"),
                            _imageName:  url.deletingPathExtension().lastPathComponent,
                           _coordinates: Coordinates(x: Float(Double.random(in: -100...100)), y: Float(Double.random(in: -100...100))),
                           _rmUML: room.roomURL.appendingPathComponent("ReferenceMarker"),
                           _physicalWidth: 0.0
                       )
                        
                        room.addReferenceMarker(referenceMarker: referenceMarker)
                        
                        let referenceMarkerURL = room.roomURL.appendingPathComponent("ReferenceMarker")
                        referenceMarker.saveMarkerData(
                            to: referenceMarkerURL.appendingPathComponent("Marker Data.json"),
                            old: referenceMarker.imageName,
                            new: referenceMarker.imageName,
                            size: 0.0
                        )
                        
                    } catch {
                        errorMessage = "Failed to save the image: \(error.localizedDescription)"
                        isErrorAlertPresented = true
                    }
                }
            }
        }
        .confirmationDialog("How do you want to create the \(room.name) planimetry?", isPresented: $isOptionsSheetPresented, titleVisibility: .visible) {
            
            NavigationLink(destination: RoomScanningView(room: room)){
                Button("Create With AR") {
                    let fileManager = FileManager.default
                    let filePaths = [
                        room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"),
                        room.roomURL.appendingPathComponent("JsonParametric").appendingPathComponent("\(room.name).json"),
                        room.roomURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(room.name).plist"),
                        room.roomURL.appendingPathComponent("Maps").appendingPathComponent("\(room.name).map"),
                        room.roomURL.appendingPathComponent("JsonMaps").appendingPathComponent("\(room.name)")
                    ]

                    do {
                        for filePath in filePaths {
                            try fileManager.removeItem(at: filePath)
                            print("File at \(filePath) eliminato correttamente")
                        }
                    } catch {
                        print("Errore durante l'eliminazione di un file: \(error)")
                    }

                    
                    self.isOptionsSheetPresented = false
                    self.isNavigationScanRoomActive = true
                }
                .font(.system(size: 20))
                .bold()
           }
            
            Button("Update From File") {
                
                let fileManager = FileManager.default
                let filePaths = [
                    room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"),
                    room.roomURL.appendingPathComponent("JsonParametric").appendingPathComponent("\(room.name).json"),
                    room.roomURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(room.name).plist"),
                    room.roomURL.appendingPathComponent("Maps").appendingPathComponent("\(room.name).map"),
                    room.roomURL.appendingPathComponent("JsonMaps").appendingPathComponent("\(room.name)")
                ]

                do {
                    for filePath in filePaths {
                        try fileManager.removeItem(at: filePath)
                        print("File at \(filePath) eliminato correttamente")
                    }
                } catch {
                    print("Errore durante l'eliminazione di un file: \(error)")
                }
                
                self.isOptionsSheetPresented = false
                
                // Apri la Sheet del file picker dopo aver chiuso quella corrente
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isRoomPlanimetryUploadPicker = true
                }
            }
            .font(.system(size: 20))
            .bold()
            
            Button("Cancel", role: .cancel) {
                
            }
        }
        .confirmationDialog("Are you sure to delete Room?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive) {
                floor.deleteRoom(room: room)
                showDeleteRoomToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
                print("Room deleted and navigating back")
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .toast(isPresenting: $showAddRoomPlanimetryToast) {
            AlertToast(type: .complete(Color.green), title: "Room Planimetry created")
        }
        .toast(isPresenting: $showDeleteRoomToast) {
            AlertToast(type: .complete(Color.green), title: "Room deleted successfully")
        }
        .toast(isPresenting: $showRenameRoomToast){
            AlertToast(displayMode: .banner(.slide), type: .regular, title: "Room Renamed")
        }
    }
    
    @ViewBuilder
    func headerView() -> some View {
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
    }
    
    private var changeRoomColor: some View {
        ZStack{
            Color.customBackground // Imposta il colore di sfondo personalizzato
                        .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "paintpalette")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                    Text("Change Room color")
                        .font(.title)
                        .foregroundColor(.white)
                        .bold()
                }
                
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
                        
                        floor.planimetryRooms.handler.loadRoomsMaps(floor: floor, rooms: floorRooms)
                    }
            }
            .presentationDetents([.height(160)])
            .presentationDragIndicator(.visible)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.customBackground)
            .cornerRadius(16)
        }
    }
    
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            switch selectedTab {
            case 0:
                Menu {
                    Button(action: { isRenameSheetPresented = true }) {
                        Label("Rename Room", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(action: { isOptionsSheetPresented = true }) {
                        Label("Create Planimetry", systemImage: "plus")
                    }
                    .disabled(FileManager.default.fileExists(atPath: room.roomURL
                        .appendingPathComponent("MapUsdz")
                        .appendingPathComponent("\(room.name).usdz")
                        .path))
                    
                    Button(action: {
                        alertMessage = """
                        Proceeding with this update will permanently delete the current \(room.name)'s planimetry.

                        This action cannot be undone. Are you sure you want to continue?
                        """
                        showRoomUpdatePlanimetryAlert = true
                    }) {
                        Label("Update Planimetry", systemImage: "arrow.clockwise")
                    }
                    .disabled(!FileManager.default.fileExists(atPath: room.roomURL
                        .appendingPathComponent("MapUsdz")
                        .appendingPathComponent("\(room.name).usdz")
                        .path))
                    
                    Divider()
                    
                    Button(action: { isColorPickerPopoverPresented = true }) {
                        Label("Change Room Color", systemImage: "paintpalette")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Room", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue, .blue)
                }
                
            case 1:
                Menu {
//                    Button(action: { isRoomPlanimetryUploadPicker = true }) {
//                        Label("Create Room Position Automatic Mode", systemImage: "mappin.and.ellipse")
//                    }
//                    .disabled(true)
                    
                    NavigationLink(destination: AutomaticRoomPositionView(floor: self.floor, room: self.room)) {
                        Label("Create Room Position Association Mode", systemImage: "point.topleft.down.to.point.bottomright.filled.curvepath")
                    }
                    
//                    Divider()
                    
                    NavigationLink(destination: ManualRoomPositionView(floor: self.floor, room: self.room)) {
                        Label("Correct Room Position", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                    }
                    .disabled(!doesMatrixExist(for: room.name, in: floor.associationMatrix))
                    
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue, .blue)
                }
                
            case 2:
                Menu {
                    Button(action: { isReferenceMarkerUploadPicker = true }) {
                        Label("Add from File System", systemImage: "photo")
                    }

                    
                    NavigationLink(destination: RoomCameraRMView(isPresented: .constant(false),
                                                                 room: room).edgesIgnoringSafeArea(.all).toolbarBackground(.hidden, for: .navigationBar) ) {
                        Label("Add using Camera", systemImage: "camera.viewfinder")
                    }
                    
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue, .blue)
                }
                
                
               
                
            case 3:
                Menu {
                    NavigationLink(
                        destination: AddStairsConnectionView(
                            building: building,
                            floor: floor,
                            initialSelectedFloor: floor,
                            initialSelectedRoom: room
                        )
                    ) {
                        Label("Create Adjacent Floors Connection", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 16))
                    }.disabled(building.floors.count < 2)
                    
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .blue, .blue)
                }
                
            case 4:
                NavigationLink(destination: AddTransitionZoneView(floor: floor, room: room)) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white, .blue, .blue)
                }
                
            default:
                EmptyView()
            }
        }
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
