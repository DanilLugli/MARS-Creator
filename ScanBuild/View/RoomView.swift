import SwiftUI
import Foundation

struct RoomView: View {
    
    @State var room: Room
    @ObservedObject var building: Building
    @State var floor: Floor
    @State private var searchText: String = ""

    @State private var newBuildingName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedConnection: TransitionZone? = nil
    @State private var selectedTab: Int = 0
    
    @State private var selectedFileURL: URL?
    @State private var isRenameSheetPresented = false
    @State private var isNavigationActive = false
    @State private var isConnectionAdjacentFloor = false
    @State private var isRoomPlanimetryUploadPicker = false
    @State private var isConnectionSameFloor = false
    @State private var isErrorAlertPresented = false
    @State private var errorMessage: String = ""
    
    @State private var showUpdateOptionsAlert = false
    @State private var showUpdateAlert = false
    @State private var isOptionsSheetPresented = false
    @State private var alertMessage = ""

    
    var mapView = SCNViewContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("\(building.name) > \(floor.name) > \(room.name)")
                        .font(.system(size: 14))
                        .fontWeight(.heavy)
                    
                    TabView(selection: $selectedTab) {
                        VStack {
                            if isDirectoryEmpty(url: room.roomURL.appendingPathComponent("MapUsdz")) {
                                Text("Add Planimetry with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            } else {
                                VStack {
                                    ZStack {
                                        mapView
                                            .border(Color.white)
                                            .cornerRadius(10)
                                            .padding()
                                            .shadow(color: Color.gray, radius: 3)
                                        
                                        VStack {
                                            HStack {
                                                Spacer() // Push buttons to the right
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
                                            }
                                            Spacer() // Push buttons to the top
                                        }
                                    }
                                }
                                .onAppear {
                                    mapView.loadRoomMaps(name: room.name, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Room Planimetry", systemImage: "map.fill")
                        }
                        .tag(0)
                        
                        VStack {
                            if room.referenceMarkers.isEmpty {
                                VStack {
                                    Text("Add Marker with + icon")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 50) {
                                        ForEach(filteredMarker, id: \.id) { marker in
                                            Button(action: {
                                                selectedMarker = marker
                                            }) {
                                                MarkerCardView(imageName: marker.image).padding()
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
                            Label("Marker", systemImage: "mappin.and.ellipse")
                        }
                        .tag(1)
                        
                        VStack {
                            if floor.associationMatrix.isEmpty {
                                VStack {
                                    let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                    MatrixCardView(floor: floor.name, room: room.name, exist: isSelected, date: Date(), rowSize: 1)
                                }
                                .padding()
                            } else {
                                VStack {
                                    let isSelected = floor.isMatrixPresent(named: room.name, inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                                    MatrixCardView(floor: room.name, room: room.name, exist: isSelected, date: Date(), rowSize: 1)
                                }
                                .padding()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Room Position", systemImage: "sum")
                        }
                        .tag(2)
                        
                        VStack {
                            if room.transitionZones.isEmpty {
                                VStack {
                                    Text("No Connection for \(room.name)")
                                        .foregroundColor(.gray)
                                        .font(.headline)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.customBackground)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 50) {
                                        ForEach(filteredConnection, id: \.id) { transitionZone in
                                            Button(action: {
                                                selectedConnection = transitionZone // Assicurati che `selectedConnection` sia dichiarato come @State
                                            }) {
                                                if let connection = transitionZone.connection as? AdjacentFloorsConnection {
                                                    ListConnectionCardView(
                                                        floor: floor.name,
                                                        room: room.name,
                                                        targetFloor: connection.targetFloor,
                                                        targetRoom: connection.targetRoom,
                                                        transitionZone: transitionZone.name,
                                                        exist: true,
                                                        date: Date(),
                                                        rowSize: 1
                                                    )
                                                    .padding(.top)
                                                } else if let connection = transitionZone.connection as? SameFloorConnection {
                                                    ListConnectionCardView(
                                                        floor: floor.name,
                                                        room: connection.targetRoom,
                                                        targetFloor: floor.name,
                                                        targetRoom: connection.targetRoom,
                                                        transitionZone: transitionZone.name,
                                                        exist: false,
                                                        date: Date(),
                                                        rowSize: 1
                                                    )
                                                    .padding(.top)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.customBackground)
                        .tabItem {
                            Label("Connections", systemImage: "arrow.left.arrow.right")
                        }
                        .tag(3)
                    }
                }
                .background(Color.customBackground)
                .foregroundColor(.white)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ROOM")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        Menu {
                            
                            Button(action: {
                                isRoomPlanimetryUploadPicker = true
                            }) {
                                Label("Rename Room", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                self.isNavigationActive = true
                            }) {
                                Label("Create Planimetry", systemImage: "plus")
                            }.disabled(FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                            
                            Button(action: {
                                isRoomPlanimetryUploadPicker = true
                            }) {
                                Label("Upload Planimetry from File", systemImage: "square.and.arrow.down")
                            }.disabled(FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                            
                            Button(action: {
                                alertMessage = "If you proceed with the update, the current floor plan will be deleted.\nThis action is irreversible, are you sure you want to continue?"
                                showUpdateAlert = true
                            }) {
                                Label("Update Planimetry", systemImage: "arrow.clockwise")
                            }.disabled(!FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                            
                            Divider()
                            
                            
                            Button(role: .destructive, action: {
                                //TODO: Aggiustare l'eliminazione della room
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red) // Imposta l'icona in rosso
                                    Text("Delete Room")
                                        .foregroundColor(.red) // Imposta il testo in rosso
                                }
                            }
                            
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue, .blue)
                        }
                        
                        NavigationLink(destination: ScanningView(namedUrl: room), isActive: $isNavigationActive) {
                            EmptyView()
                        }
                        
                    } 
                    else if selectedTab == 1 {
                        Button(action: {
                            isRoomPlanimetryUploadPicker = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                        }
                    } 
                    else if selectedTab == 2 {
                        NavigationLink(destination: RoomPositionView(floor: floor, room: room), isActive: $isConnectionAdjacentFloor) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                                .onTapGesture {
                                    self.isConnectionAdjacentFloor = true
                                }
                        }
                    }
                    else if selectedTab == 3 {
                        ZStack{
                            Menu {
                                
                                Button(action: {
                                    isConnectionSameFloor = true
                                }) {
                                    Label("Create Same Floor Connection", systemImage: "arrow.left.arrow.right")
                                }
                                
                                Button(action: {
                                    isConnectionAdjacentFloor = true
                                }) {
                                    Label("Create Adjacent Floors Connection", systemImage: "arrow.up.arrow.down")
                                }
                                
                                // Navigazione verso una terza vista
                                Button(action: {
                                    //TODO: Create in future Connection with Elevator
                                }) {
                                    Label("Create Elevator Connection", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
                                }
                                
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(.white, .blue, .blue)
                            }
                            
                            // NavigationLink per AddStairsConnectionView, attivato al di fuori del menu
                            NavigationLink(
                                destination: AddStairsConnectionView(building: building, initialSelectedFloor: floor, initialSelectedRoom: room),
                                isActive: $isConnectionAdjacentFloor,
                                label: {
                                    EmptyView()
                                }
                            )
                            
                            NavigationLink(
                                destination: AddSameConnectionView(selectedBuilding: building, initialSelectedFloor: floor, initialSelectedRoom: room),
                                isActive: $isConnectionSameFloor,
                                label: {
                                    EmptyView()
                                }
                            )
                        }
                        
                    }
                }
            }.alert(isPresented: $isErrorAlertPresented) {
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
                    dismissButton: .default(Text("OK")){
                        isOptionsSheetPresented = true
                    }
                )
            }
            .sheet(isPresented: $isRoomPlanimetryUploadPicker) {
                FilePickerView { url in
                    selectedFileURL = url
                    
                    // Definisci il percorso di destinazione per il file selezionato
                    let destinationURL = room.roomURL
                        .appendingPathComponent("MapUsdz")
                        .appendingPathComponent("\(room.name).usdz")
                    
                    // Crea la directory "MapUsdz" se non esiste già
                    let fileManager = FileManager.default
                    let mapUsdzDirectory = room.roomURL.appendingPathComponent("MapUsdz")
                    
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
                        isErrorAlertPresented = true
                    }
                }
            }
            .sheet(isPresented: $isOptionsSheetPresented) {
                VStack {
                    Text("Choose an option")
                        .font(.system(size: 26))
                        .fontWeight(.bold)


                    Button(action: {
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
                            self.isRoomPlanimetryUploadPicker = true
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
                .background(Color.customBackground)
                .padding()
            }
            .sheet(item: $selectedMarker) { marker in
                VStack {
                    Text("Position Marker")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .foregroundColor(.white)               
                    mapView.border(Color.white).cornerRadius(10).padding().shadow(color: Color.gray, radius: 3)
                    Spacer()
                }
                .padding()
                .background(Color.customBackground.ignoresSafeArea())
            }
        }
    }
    
    var tabTitle: String {
        switch selectedTab {
        case 0: return "Planimentry"
        case 1: return "Markers"
        case 2: return "Room Position"
        case 3: return "Transition Zone"
        default: return ""
        }
    }
    
    var filteredMarker: [ReferenceMarker] {
        if searchText.isEmpty {
            return room.referenceMarkers
        } else {
            return room.referenceMarkers.filter { $0.imageName.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var filteredConnection: [TransitionZone] {
        let filteredZones = room.transitionZones.filter { transitionZone in
            transitionZone.connection != nil
        }
        
        if searchText.isEmpty {
            return filteredZones
        } else {
            return filteredZones.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func isDirectoryEmpty(url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            return contents.isEmpty
        } catch {
            print("Error checking directory contents: \(error)")
            return true
        }
    }}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        return RoomView(room: room, building: building, floor: floor)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
