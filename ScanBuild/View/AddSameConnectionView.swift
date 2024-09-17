import SwiftUI
import Foundation

struct AddSameConnectionView: View {
    
    var selectedBuilding: Building
    @State var selectedFloor: Floor?
    @State var selectedRoom: Room?
    
    var initialSelectedFloor: Floor? = nil
    var initialSelectedRoom: Room? = nil

    @State private var fromTransitionZone: TransitionZone?
    @State private var toTransitionZone: TransitionZone?

    @State private var fromFloor: Floor?
    @State private var fromRoom: Room?

    @State private var step: Int = 1  // Step of the connection creation process
    @State private var showConfirmDialog = false

    @State private var showActionSheetFloor = false
    @State private var showActionSheetRoom = false
    @State private var showActionSheetTZ = false
    
    @State var mapView = SCNViewContainer()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
                ConnectedDotsView(labels: ["1° Connection From", "2° Connection To", "Confirm"], progress: step == 1 ? 1 : (step == 2 ? 2 : 3))
                    .padding(.top)
                
                HStack {
                    VStack {
                        Text("Floor")
                            .font(.system(size: 22))
                            .fontWeight(.heavy)
                        HStack {
                            ConnectionCardView(name: selectedFloor?.name ?? "Choose\nFloor", isSelected: selectedFloor != nil)
                                .padding()
                                .onTapGesture {
                                    showActionSheetFloor = true
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
                            ConnectionCardView(name: selectedRoom?.name ?? "Choose\nRoom", isSelected: selectedRoom != nil)
                                .padding()
                                .onTapGesture {
                                    showActionSheetRoom = true
                                }
                                .actionSheet(isPresented: $showActionSheetRoom) {
                                    ActionSheet(
                                        title: Text("Select a Room"),
                                        buttons: actionSheetRoomButtons()
                                    )
                                }
                        }
                    }
                    
                    VStack {
                        Text("Transition\nZone")
                            .font(.system(size: 14))
                            .fontWeight(.heavy)
                        
                        HStack {
                            ConnectionCardView(name: (step == 1 ? fromTransitionZone?.name : toTransitionZone?.name) ?? "Choose\nT. Z.", isSelected: (step == 1 ? fromTransitionZone : toTransitionZone) != nil)
                                .padding()
                                .onTapGesture {
                                    showActionSheetTZ = true
                                }
                                .actionSheet(isPresented: $showActionSheetTZ) {
                                    ActionSheet(
                                        title: Text("Select a Transition Zone"),
                                        buttons: actionSheetTZButtons()
                                    )
                                }
                        }
                    }
                }
                
                VStack {
                    ZStack {
                        mapView
                            .border(Color.white)
                            .frame(width: 360, height: 360)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }
                }
                .onChange(of: selectedRoom) { oldRoom, newRoom in
                    loadMap(for: newRoom)
                }
                .onAppear {
                    loadMap(for: selectedRoom)
                }

                if step == 1 && fromTransitionZone != nil {
                    Button(action: {
                        step = 2
                        selectedRoom = nil
                    }) {
                        HStack {
                            Text("Next").bold()
                            Image(systemName: "arrow.right").bold()
                        }
                        .font(.system(size: 20))
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                // Conferma finale
                if step == 3 {
                    Button(action: {
                        createConnection() // Crea la connessione
                        showConfirmDialog = true
                    }) {
                        Text("Confirm Connection")
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .confirmationDialog("Do you confirm this connection?", isPresented: $showConfirmDialog) {
                        Button("Confirm") {
                            insertConnection()
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.customBackground)
            .foregroundColor(.white)
            .onAppear {
                if selectedFloor == nil {
                    selectedFloor = initialSelectedFloor
                }
                if selectedRoom == nil {
                    selectedRoom = initialSelectedRoom
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEW SAME FLOOR CONNECTION")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }
    
    // Funzioni per gestire i pulsanti dell'ActionSheet
    func actionSheetFloorButtons() -> [ActionSheet.Button] {
        
        var buttons: [ActionSheet.Button] = selectedBuilding.floors
            .filter { floor in
                // Filtra se è lo stesso piano selezionato nello step precedente (per esempio, `fromFloor`)
                if step == 2 {
                    return floor != fromFloor
                }
                return true
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
        guard let rooms = selectedFloor?.rooms else {
            return [.cancel()]
        }
        
        // Escludi la stanza selezionata nello step precedente
        var buttons: [ActionSheet.Button] = rooms
            .filter { room in
                if step == 2 {
                    return room != fromRoom
                }
                return true
            }
            .map { room in
                .default(Text(room.name)) {
                    selectedRoom = room
                }
            }
        buttons.append(.cancel())
        return buttons
    }
    
    func actionSheetTZButtons() -> [ActionSheet.Button] {
        guard let transitionZones = selectedRoom?.transitionZones else {
            return [.cancel()]
        }
        
        // Escludi la transition zone selezionata nello step precedente
        var buttons: [ActionSheet.Button] = transitionZones
            .filter { tz in
                if step == 2 {
                    return tz != fromTransitionZone
                }
                return true
            }
            .map { tz in
                .default(Text(tz.name)) {
                    if step == 1 {
                        fromTransitionZone = tz
                    } else {
                        toTransitionZone = tz
                        step = 3 // Pronto per confermare
                    }
                }
            }
        buttons.append(.cancel())
        return buttons
    }
    
    private func loadMap(for room: Room?) {
        if let room = room {
            mapView.loadRoomPlanimetry(
                room: room,
                borders: true
            )
        }
    }
    
    private func createConnection() {
        print("Connection created between \(fromTransitionZone?.name ?? "") and \(toTransitionZone?.name ?? "")")
        
        // Verifica che tutte le informazioni necessarie siano presenti
        guard let fromFloor = selectedFloor,
              let fromRoom = selectedRoom,
              let fromTransitionZone = fromTransitionZone,
              let toFloor = selectedFloor,
              let toRoom = selectedRoom,
              let toTransitionZone = toTransitionZone else {
            print("Incomplete data for creating a connection")
            return
        }
        
        // Crea la connessione tra le due TransitionZone
        let fromConnection = AdjacentFloorsConnection(name: "Connection to \(toRoom.name)", targetFloor: toFloor.name, targetRoom: toRoom.name)
        let toConnection = AdjacentFloorsConnection(name: "Connection to \(fromRoom.name)", targetFloor: fromFloor.name, targetRoom: fromRoom.name)

        // Imposta le connessioni nelle TransitionZone
        fromTransitionZone.connection = fromConnection
        toTransitionZone.connection = toConnection
        
        // Stampa per verificare che la connessione sia stata creata correttamente
        print("Connection created from \(fromRoom.name) to \(toRoom.name)")
        print("From Transition Zone Connection: \(fromConnection.targetRoom)")
        print("To Transition Zone Connection: \(toConnection.targetRoom)")
    }
    
    func insertConnection() {
        // Inserisci la connessione nel modello, salva o invia al server
    }
}


struct AddSameConnectionView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let selectedBuilding = buildingModel.initTryData()
        let floor = selectedBuilding.floors.first!
        let room = floor.rooms.first!
        
        return AddSameConnectionView(selectedBuilding: selectedBuilding, initialSelectedFloor: floor, initialSelectedRoom: room)
    }
}
