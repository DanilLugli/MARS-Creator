import SwiftUI
import Foundation

struct AddConnectionView: View {
    
    var selectedBuilding: Building
    @State var selectedFloor: Floor? = nil
    @State var selectedRoom: Room? = nil
    @State private var fromFloor: Floor?
    @State private var fromRoom: Room?
    @State private var fromTransitionZone: TransitionZone?
    
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var showAlert: Bool = false
    @State private var isElevator: Bool = false
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(selectedBuilding.name) > New Connection")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                ConnectedDotsView(labels: ["1° T.Z.", "2° T.Z."], progress: fromTransitionZone == nil ? 1 : 2).padding()
                Text("Choose Floor").font(.system(size: 22))
                    .fontWeight(.heavy)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedBuilding.floors) { floor in
                            DefaultCardView(name: floor.name, date: floor.lastUpdate, rowSize: 1, isSelected: selectedFloor?.id == floor.id  ).padding()
                                .onTapGesture {
                                    selectedFloor = floor
                                }
                        }
                    }
                }
                
                if let selectedFloor = selectedFloor {
                    VStack {
                        Divider()
                        Text("Choose Room").font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedFloor.rooms) { room in
                                    if room.name != fromRoom?.name {
                                        DefaultCardView(name: room.name, date: room.lastUpdate, rowSize: 2, isSelected: selectedRoom?.id == room.id  ).padding()
                                            .onTapGesture {
                                                selectedRoom = room
                                            }
                                    }
                                }
                            }
                        }
                    }.padding()
                }
                
                if let selectedRoom = selectedRoom {
                    VStack {
                        Divider()
                        Text("Choose Transition Zone").font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedRoom.transitionZones) { transitionZone in
                                    DefaultCardView(name: transitionZone.name, date: Date(), rowSize: 1, isSelected: selectedTransitionZone?.id == transitionZone.id )
                                        .onTapGesture {
                                            selectedTransitionZone = transitionZone
                                        }
                                }
                            }
                        }
                    }.padding()
                }
                
                if selectedTransitionZone != nil {
                    Spacer()
                    Button(action: {
                        if fromTransitionZone != nil {
                            insertConnection()
                            showAlert = true
                            dismiss()
                        } else {
                            fromTransitionZone = selectedTransitionZone
                            fromFloor = selectedFloor
                            fromRoom = selectedRoom
                        }
                        
                        selectedTransitionZone = nil
                        selectedRoom = nil
                        selectedFloor = nil
                    }) {
                        VStack {
                            if (fromTransitionZone != nil) {
                                Toggle(isOn: $isElevator) {
                                    Text("Elevator Connection")
                                }
                                .toggleStyle(SwitchToggleStyle()).padding()
                            }
                            Text(fromTransitionZone == nil ? "SELECT START" : "SAVE")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.customBackground)
            .foregroundColor(.white)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Connection Created"), message: Text("Connection created successfully"))
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEW CONNECTION")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                HStack {
//                    NavigationLink(destination: AddBuildingView()) {
//                        Image(systemName: "plus.circle.fill")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(width: 31, height: 31)
//                            .foregroundColor(.blue)
//                            .background(Circle().fill(Color.white).frame(width: 31, height: 31))
//                    }
//                    Button(action: {
//                        // Azione per il pulsante "info.circle"
//                        print("Info button tapped")
//                    }) {
//                        Image(systemName: "info.circle")
//                            .foregroundColor(.white)
//                            .padding(8)
//                            .frame(width: 30, height: 30)
//                            .background(Color.blue)
//                            .clipShape(Circle())
//                    }
//                }
//            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }
    
    private func createConnection() -> (Connection, Connection)? {
        if (fromFloor?.name == selectedFloor?.name) {
            if let fromRoomName = fromRoom?.name, let toRoomName = selectedRoom?.name {
                let connection = SameFloorConnection(name: "Same Floor Connection", targetRoom: toRoomName)
                let mirrorConnection = SameFloorConnection(name: "Same Floor Connection", targetRoom: fromRoomName)
                return (connection, mirrorConnection)
            }
        }
        
        if !isElevator {
            if let fromFloorName = fromFloor?.name, let fromRoomName = fromRoom?.name, let toFloorName = selectedFloor?.name, let toRoomName = selectedRoom?.name {
                let connection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: toFloorName, targetRoom: toRoomName)
                let mirrorConnection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: fromFloorName, targetRoom: fromRoomName)
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
        
        return AddConnectionView(selectedBuilding: selectedBuilding)
    }
}
