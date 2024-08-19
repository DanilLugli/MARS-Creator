import SwiftUI
import Foundation

struct AddConnectionView: View {
    
    var selectedBuilding: Building
    
    var initialSelectedFloor: Floor? = nil
    var initialSelectedRoom: Room? = nil
    
    @State var selectedFloor: Floor? = nil
    @State var selectedRoom: Room?
    @State private var fromTransitionZone: TransitionZone?
    
    @State private var fromFloor: Floor?
    @State private var fromRoom: Room?
    
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var showAlert: Bool = false
    @State private var isElevator: Bool = false
    
    @State private var isMenuPresented: Bool = false
    @State private var showActionSheetFloor = false
    @State private var showActionSheetRoom = false
    @State private var showActionSheetTZ = false
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Text("\(selectedBuilding.name) > New Connection")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                ConnectedDotsView(labels: ["1° Connection From", "2° Connection To", "3° Confirm"], progress: fromTransitionZone == nil ? 1 : 2).padding(.top)
                
                
                
                HStack{
                    VStack{
                        Text("Floor")
                            .font(.system(size: 22))
                            .fontWeight(.heavy)
                        
                        HStack {
                            ConnectionCardView(name: selectedFloor?.name ?? "Choose\nFloor", isSelected: selectedFloor != nil)
                                .padding()
                                .onTapGesture {
                                    showActionSheetFloor = true // Mostra l'ActionSheet al tap
                                }
                                .actionSheet(isPresented: $showActionSheetFloor) {
                                    ActionSheet(
                                        title: Text("Select a Floor"),
                                        buttons: actionSheetFloorButtons()
                                    )
                                }
                        }
                    }
                    
                    
                    
                    VStack{
                        Text("Room")
                            .font(.system(size: 22))
                            .fontWeight(.heavy)
                        
                        
                        HStack {
                            ConnectionCardView(name: selectedRoom?.name ?? "Choose\nRoom", isSelected: selectedRoom != nil).padding()
                                .onTapGesture {
                                    showActionSheetRoom = true // Mostra l'ActionSheet al tap
                                }
                                .actionSheet(isPresented: $showActionSheetRoom) {
                                    ActionSheet(
                                        title: Text("Select a Room"),
                                        buttons: actionSheetRoomButtons()
                                    )
                                }
                            
                        }
                    }
                    
                    
                    
                    VStack{
                        Text("Transition\nZone")
                            .font(.system(size: 14))
                            .fontWeight(.heavy)
                        
                        HStack {
                            ConnectionCardView(name: selectedTransitionZone?.name ?? "Choose\nT. Z.", isSelected: selectedTransitionZone != nil ).padding()
                                .onTapGesture {
                                    showActionSheetTZ = true // Mostra l'ActionSheet al tap
                                }
                                .actionSheet(isPresented: $showActionSheetTZ) {
                                    ActionSheet(
                                        title: Text("Select a Transition Zone"),
                                        buttons: actionSheetTZButtons()
                                    )
                                }
                        }
                        
                    }
                    
                }.padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.customBackground)
            .foregroundColor(.white)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Connection Created"), message: Text("Connection created successfully"))
            }
            .onAppear {
                
                DispatchQueue.main.async {
                    selectedFloor = initialSelectedFloor
                    selectedRoom = initialSelectedRoom
                }
                
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEW CONNECTION")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }
    
    func actionSheetFloorButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = selectedBuilding.floors.map { floor in
                .default(Text(floor.name)) {
                    selectedFloor = floor
                    isMenuPresented = false
                }
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    func actionSheetRoomButtons() -> [ActionSheet.Button] {
        guard let rooms = selectedFloor?.rooms else {
            return [.cancel()]
        }
        
        // Crea un array di pulsanti per ogni stanza
        var buttons: [ActionSheet.Button] = rooms.map { room in
                .default(Text(room.name)) {  // Qui specifica chiaramente che è un ActionSheet.Button
                    selectedRoom = room
                    isMenuPresented = false
                }
        }
        // Aggiungi il pulsante "Cancel" alla fine
        buttons.append(.cancel())
        
        return buttons
    }
    
    func actionSheetTZButtons() -> [ActionSheet.Button] {
        
        guard let transitionZone = selectedRoom?.transitionZones else {
            return [.cancel()]
        }
        
        var buttons: [ActionSheet.Button] = transitionZone.map { transitionZone in
                .default(Text(transitionZone.name)) {
                    selectedTransitionZone = transitionZone
                    isMenuPresented = false
                }
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func createConnection() -> (Connection, Connection)? {
        if (fromFloor?.name == selectedFloor?.name) {
            if let fromRoomName = fromRoom?.name, let toRoomName = selectedRoom?.name {
                let connection = SameFloorConnection(name: "Same Floor Connection", targetRoom: toRoomName)
                let mirrorConnection = SameFloorConnection(name: "Same Floor Connection", targetRoom: fromRoomName)
                
                let newTransitionZone = TransitionZone(name: "New Transition Zone", connection: mirrorConnection, transitionArea: Coordinates(x: 1, y: 2))
                
                // Aggiungi la nuova TransitionZone all'array transitionZones della stanza
                do {
                    try initialSelectedRoom?.addTransitionZone(transitionZone: newTransitionZone)
                } catch {
                    print("Errore durante l'aggiunta della TransitionZone: \(error)")
                }
                return (connection, mirrorConnection)
            }
        }
        
        if !isElevator {
            if let fromFloorName = fromFloor?.name, let fromRoomName = fromRoom?.name, let toFloorName = selectedFloor?.name, let toRoomName = selectedRoom?.name {
                let connection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: toFloorName, targetRoom: toRoomName)
                let mirrorConnection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: fromFloorName, targetRoom: fromRoomName)
                
                let newTransitionZone = TransitionZone(name: "New Transition Zone", connection: mirrorConnection, transitionArea: Coordinates(x: 1, y: 2))
                
                // Aggiungi la nuova TransitionZone all'array transitionZones della stanza
                do {
                    try initialSelectedRoom?.addTransitionZone(transitionZone: newTransitionZone)
                } catch {
                    print("Errore durante l'aggiunta della TransitionZone: \(error)")
                }
                
                return (connection, mirrorConnection)
            }
        }
        
        if let fromFloorName = fromFloor?.name, let fromRoomName = fromRoom?.name, let toFloorName = selectedFloor?.name, let toRoomName = selectedRoom?.name {
            let connection = ElevatorConnection(name: "Elevator Connection", targetFloor: toFloorName, targetRoom: toRoomName)
            let mirrorConnection = ElevatorConnection(name: "Elevator Connection", targetFloor: fromFloorName, targetRoom: fromRoomName)
            return (connection, mirrorConnection)
        }
        return nil
    }
    
    func insertConnection() {
        if let (fromConnection, toConnection) = createConnection() {
            fromTransitionZone?.connection = fromConnection
            selectedTransitionZone?.connection = toConnection
        }
    }
    
    
}



struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let selectedBuilding = buildingModel.initTryData()
        let floor = selectedBuilding.floors.first!
        let room = floor.rooms.first!
        
        return AddConnectionView(selectedBuilding: selectedBuilding, initialSelectedFloor: floor, initialSelectedRoom: room)
    }
}
