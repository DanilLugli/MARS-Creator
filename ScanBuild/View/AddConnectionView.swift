import SwiftUI
import Foundation

struct AddConnectionView: View {
    
    enum ConnectionType: String, CaseIterable, Identifiable {
        case sameFloor = "Same Floor"
        case adjacentFloors = "Adjacent Floors"
        case elevator = "Elevator"
        
        var id: String { self.rawValue }
    }
    
    @State var fromFloor: Floor?
    @State var fromRoom: Room?
    @State var fromTransitionZone: TransitionZone?
    
    @State private var selectedFloor: Floor? = nil
    @State private var selectedRoom: Room? = nil
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var showAlert: Bool = false
    @State private var selectedConnectionType: ConnectionType? = nil
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    var selectedBuilding: Building
    
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
                            if floor.id != fromFloor?.id {
                                DefaultCardView(name: floor.name, date: floor.lastUpdate, rowSize: 2)
                                    .onTapGesture {
                                        selectedFloor = floor
                                    }
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
                                    DefaultCardView(name: room.name, date: room.lastUpdate, rowSize: 2).onTapGesture {
                                        selectedRoom = room
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
                                    DefaultCardView(name: transitionZone.name, date: Date(),
                                                    rowSize: 2).onTapGesture {
                                        selectedTransitionZone = transitionZone
                                    }
                                }
                            }
                        }
                    }.padding()
                }
                
                if selectedTransitionZone != nil {
                    VStack {
                        Divider()
                        Text("Select Connection Type").font(.system(size: 22))
                            .fontWeight(.heavy)
                        Picker("Connection Type", selection: $selectedConnectionType) {
                            ForEach(ConnectionType.allCases) { type in
                                Text(type.rawValue).tag(type as ConnectionType?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                }
                
                if selectedConnectionType != nil {
                    Spacer()
                    Button(action: {
                        if fromTransitionZone != nil {
                            //createConnection()
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
                        Text(fromTransitionZone == nil ? "SELECT START" : "SAVE")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink(destination: AddBuildingView()) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 31, height: 31)
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white).frame(width: 31, height: 31))
                    }
                    Button(action: {
                        // Azione per il pulsante "info.circle"
                        print("Info button tapped")
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(width: 30, height: 30)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }
    
//    private func createConnection() {
//        guard let fromTransitionZone = fromTransitionZone, let selectedTransitionZone = selectedTransitionZone, let connectionType = selectedConnectionType else {
//            return
//        }
//        
//        let connection: Connection
//        switch connectionType {
//        case .sameFloor:
//            connection = SameFloorConnection(name: "Same Floor Connection", targetRoom: fromRoom?.name!)
//        case .adjacentFloors:
//            connection = AdjacentFloorsConnection(name: "Adjacent Floors Connection", targetFloor: fromFloor.name!, targetRoom: fromRoom!)
//        case .elevator:
//            connection = ElevatorConnection(name: "Elevator Connection", targetFloor: fromFloor.name!, targetRoom: fromRoom.name!)
//        }
//        
//        fromTransitionZone.connection = connection
//    }
}

struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let selectedBuilding = buildingModel.initTryData()
        let floor = selectedBuilding.floors.first!
        let room = floor.rooms.first!
        let transitionZone = room.transitionZones.first!
        
        return AddConnectionView(fromFloor: floor, fromRoom: room, fromTransitionZone: transitionZone, selectedBuilding: selectedBuilding)
    }
}
