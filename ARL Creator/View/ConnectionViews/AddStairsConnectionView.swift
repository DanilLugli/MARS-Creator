import Foundation
import AlertToast
import SwiftUI

struct AddStairsConnectionView: View {
    
    @ObservedObject var building: Building
    @ObservedObject var floor: Floor
    
    @State var selectedFloor: Floor?
    @State var selectedRoom: Room?
    
    var initialSelectedFloor: Floor
    var initialSelectedRoom: Room
    
    @State private var fromFloor: Floor
    @State private var fromRoom: Room
    
    @State var mapViewFromRoom = SCNViewContainer()
    @State var mapViewToRoom = SCNViewContainer()
    
    @State var mapFinalViewFromRoom = SCNViewContainer()
    @State var mapFInalViewToRoom = SCNViewContainer()
    
    @State var altitude: Float = 0
    
    @State private var step: Int = 1
    @State private var showConfirmDialog = false
    
    @State private var showActionSheetFloor = false
    @State private var showActionSheetRoom = false
    @State private var showConnectionCreateToast = false
    
    @Environment(\.dismiss) private var dismiss
    
    init(building: Building, floor: Floor, initialSelectedFloor: Floor, initialSelectedRoom: Room) {
        self.building = building
        self.floor = floor
        self.initialSelectedFloor = initialSelectedFloor
        self.initialSelectedRoom = initialSelectedRoom
        self._fromFloor = State(initialValue: initialSelectedFloor)
        self._fromRoom = State(initialValue: initialSelectedRoom)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ConnectedDotsView(
                    labels: ["1° From", "2° To", "3° Altitude", "Confirm"],
                    progress: step
                )
                
                if step != 3 && step != 4 {
                    HStack {
                        VStack {
                            Text("Floor")
                                .font(.system(size: 22))
                                .fontWeight(.heavy)
                            
                            HStack {
                                ConnectionCardView(
                                    name: step == 1 ? fromFloor.name : (selectedFloor?.name ?? "Select Floor"),
                                    isSelected: step == 1 || (step == 2 && selectedFloor != nil),
                                    isFloor: true
                                )
                                .padding()
                                .onTapGesture {
                                    if step == 2 {
                                        showActionSheetFloor = true
                                    }
                                }
                                .actionSheet(isPresented: $showActionSheetFloor) {
                                    ActionSheet(
                                        title: Text("Select a Floor"),
                                        buttons: actionSheetFloorButtons()
                                    )
                                }
                            }
                        }
                        
                        VStack {
                            Text("Room")
                                .font(.system(size: 22))
                                .fontWeight(.heavy)
                            
                            HStack {
                                ConnectionCardView(
                                    name: step == 1 ? fromRoom.name : (selectedRoom?.name ?? "Select Room"),
                                    isSelected: step == 1 || (step == 2 && selectedRoom != nil),
                                    isFloor: false
                                )
                                .padding()
                                .onTapGesture {
                                    if step == 2 {
                                        showActionSheetRoom = true
                                    }
                                }
                                .actionSheet(isPresented: $showActionSheetRoom) {
                                    ActionSheet(
                                        title: Text("Select a Room"),
                                        buttons: actionSheetRoomButtons()
                                    )
                                }
                            }
                        }
                    }
                }
                
                VStack {
                    switch step {
                    case 1:
                        ZStack {
                            mapViewFromRoom
                                .border(Color.white)
                                .frame(width: 360, height: 360)
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.gray, radius: 3)
                        }
                        .onAppear {
                            loadMap(for: fromRoom, on: mapViewFromRoom)
                        }
                        
                    case 2:
                        ZStack {
                            mapViewToRoom
                                .border(Color.white)
                                .frame(width: 360, height: 360)
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.gray, radius: 3)
                        }
                        .onAppear {
                            if let room = selectedRoom {
                                loadMap(for: room, on: mapViewToRoom)
                            }
                        }
                        
                    case 3:
                        VStack {
                            FloorAltitudeTabView(building: building, floor: floor, altitudeY: $altitude)
                        }
                        
                    case 4:
                        VStack(spacing: 20) {
                            Text("Review Connection")
                                .font(.system(size: 18, weight: .heavy))
                                .bold()
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Text("From Room")
                                        .font(.system(size: 16, weight: .bold))
                                    mapViewFromRoom
                                        .border(Color.white)
                                        .frame(width: 160, height: 160)
                                        .cornerRadius(10)
                                        .padding()
                                        .shadow(color: Color.gray, radius: 3)
                                }
                                
                                VStack {
                                    Text("To Room")
                                        .font(.system(size: 16, weight: .bold))
                                    mapViewToRoom
                                        .border(Color.white)
                                        .frame(width: 160, height: 160)
                                        .cornerRadius(10)
                                        .padding()
                                        .shadow(color: Color.gray, radius: 3)
                                }
                            }
                            
                            Text(String(format: "Altitude Difference: %.2f", altitude != 0 ? altitude : 10.0))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.customBackground)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.gray, radius: 2)
                            
                            Spacer()
                        }
                        
                    default:
                        EmptyView()
                    }
                }
                
                switch step {
                case 1,
                     2 where selectedFloor != nil && selectedRoom != nil,
                     3 where altitude != 0.0:
                    Spacer()
                    Button(action: {
                        switch step {
                        case 1:
                            step = 2
                            selectedFloor = nil
                            selectedRoom = nil
                        case 2:
                            step = 3
                        case 3:
                            step = 4
                            loadMap(for: initialSelectedRoom, on: mapViewFromRoom)
                            loadMap(for: selectedRoom, on: mapViewToRoom)
                        default:
                            break
                        }
                    }) {
                        HStack {
                            Text("Next").bold()
                            Image(systemName: "arrow.right").bold()
                        }
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .frame(width: 160, height: 50)
                        .foregroundStyle(.white)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(30)
                        .bold()
                    }
                    .disabled(step == 2 && (selectedFloor == nil || selectedRoom == nil))
                    
                case 4:
                    Spacer()
                    Button(action: {
                        showConfirmDialog = true
                    }) {
                        Text("Confirm Connection")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .frame(width: 200, height: 50)
                            .foregroundStyle(.white)
                            .background(Color.green)
                            .cornerRadius(30)
                            .bold()
                    }
                    .confirmationDialog("Do you confirm this connection?", isPresented: $showConfirmDialog) {
                        Button("Confirm") {
                            createConnection()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                    
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationTitle("Add New Stairs Connection")
        .background(Color.customBackground.ignoresSafeArea())
        .toast(isPresenting: $showConnectionCreateToast) {
            AlertToast(type: .complete(Color.green), title: "Connection created")
        }
    }
    
    
    private func loadMap(for room: Room?, on mapView: SCNViewContainer) {
        if let room = room {
            mapView.loadRoomPlanimetry(
                room: room,
                borders: false
            )
        }
    }
    
    func actionSheetFloorButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = building.floors
            .filter { floor in
                floor.name != initialSelectedFloor.name
            }
            .map { floor in
                    .default(Text(floor.name)) {
                        selectedFloor = floor
                    }
            }
        buttons.append(.cancel())
        return buttons
    }
    
    func actionSheetRoomButtons() -> [ActionSheet.Button] {
        let rooms = selectedFloor!.rooms
        
        var buttons: [ActionSheet.Button] = rooms.map { room in
                .default(Text(room.name)) {
                    selectedRoom = room
                    if step == 2 {
                        loadMap(for: room, on: mapViewToRoom)
                    }
                }
        }
        buttons.append(.cancel())
        return buttons
    }
    
    private func createConnection() {
        print("Creating connection...")
        let initialRoom = initialSelectedRoom
        let targetRoom = selectedRoom
        
        
        // Determina l'altitudine
        let altitudeDifference = self.altitude
        
        // Crea la connessione per entrambe le stanze
        let connectionFrom = AdjacentFloorsConnection(
            name: "Connection to \(String(describing: targetRoom?.name))",
            targetFloor: targetRoom?.parentFloor?.name ?? "Error",
            targetRoom: targetRoom?.name ?? "Error",
            altitude: altitudeDifference
        )
        
        let connectionTo = AdjacentFloorsConnection(
            name: "Connection to \(initialRoom.name)",
            targetFloor: initialRoom.parentFloor?.name ?? "Error",
            targetRoom: initialRoom.name,
            altitude: Float(-altitudeDifference)
        )
        
        initialRoom.connections.append(connectionFrom)
        targetRoom?.connections.append(connectionTo)
        
        
        do {
            try saveConnectionToJSON(for: initialRoom, connection: connectionFrom, to: initialRoom.roomURL)
            try saveConnectionToJSON(for: targetRoom ?? Room(
                _id: UUID(),                     // Genera un UUID casuale
                _name: "Empty Room",             // Nome predefinito
                _lastUpdate: Date(),             // Data corrente
                _planimetry: nil,                // Nessuna planimetria
                _referenceMarkers: [],           // Nessun marker di riferimento
                _transitionZones: [],            // Nessuna zona di transizione
                _scene: nil,                     // Nessuna scena
                _sceneObjects: nil,              // Nessun oggetto di scena
                _roomURL: URL(fileURLWithPath: "/tmp") // URL di default (ad esempio una directory temporanea)
            ), connection: connectionTo, to: targetRoom?.roomURL ?? URL(fileURLWithPath: ""))
            
        } catch {
            print("\(error)")
        }
        showConnectionCreateToast = true
    }
    
    private func saveConnectionToJSON(for room: Room, connection: AdjacentFloorsConnection, to url: URL) throws {
        let connectionFileURL = url.appendingPathComponent("Connection.json")
        var connections: [AdjacentFloorsConnection] = []
        
        // Controlla se il file esiste
        if FileManager.default.fileExists(atPath: connectionFileURL.path) {
            do {
                let jsonData = try Data(contentsOf: connectionFileURL)
                connections = try JSONDecoder().decode([AdjacentFloorsConnection].self, from: jsonData)
            } catch {
                print("Error reading existing connections: \(error)")
            }
        }
        
        // Aggiungi la nuova connessione
        connections.append(connection)
        
        // Salva le connessioni nel file
        let jsonData = try JSONEncoder().encode(connections)
        try jsonData.write(to: connectionFileURL)
    }
}

struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        
        return AddStairsConnectionView(building: building, floor: floor, initialSelectedFloor: floor, initialSelectedRoom: room)
    }
}
