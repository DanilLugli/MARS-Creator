import SwiftUI
import Foundation

struct AddStairsConnectionView: View {

    var building: Building
    @State var selectedFloor: Floor?
    @State var selectedRoom: Room?

    var initialSelectedFloor: Floor? = nil
    var initialSelectedRoom: Room? = nil

    @State private var fromTransitionZone: TransitionZone?
    @State private var toTransitionZone: TransitionZone?

    @State private var fromFloor: Floor?
    @State private var fromRoom: Room?
    
    @State var mapViewFromTZ = SCNViewContainer()
    @State var mapViewToTZ = SCNViewContainer()  

    @State private var step: Int = 1
    @State private var showConfirmDialog = false

    @State private var showActionSheetFloor = false
    @State private var showActionSheetRoom = false
    @State private var showActionSheetTZ = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                
                ConnectedDotsView(labels: ["1° Connection From", "2° Connection To", "Confirm"], progress: step == 1 ? 1 : (step == 2 ? 2 : 3))
                if step != 3{
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
                }
                
                VStack {
                    if step < 3 {
                        ZStack {
                            mapViewFromTZ
                                .border(Color.white)
                                .frame(width: 360, height: 360)
                                .cornerRadius(10)
                                .padding()
                                .shadow(color: Color.gray, radius: 3)
                        }
                        .onAppear {
                            loadMap(for: selectedRoom, on: mapViewFromTZ)
                        }
                        .onChange(of: selectedRoom) { oldRoom, newRoom in
                            loadMap(for: newRoom, on: mapViewFromTZ)
                        }
                    } else {
                       
                        VStack {
                            Text("NEW CONNECTION").font(.system(size: 18, weight: .heavy)).bold().bold()
                            VStack {
                                Text("FROM: ").font(.system(size: 14, weight: .heavy)).bold()
                                mapViewFromTZ
                                    .border(Color.white)
                                    .frame(width: 360, height: 220)
                                    .cornerRadius(10)
                                    .padding()
                                    .shadow(color: Color.gray, radius: 3)
                            }
                            
                            Divider()
                            Spacer()
                            
                            VStack {
                                Text("TO: ").font(.system(size: 14, weight: .heavy)).bold()
                                mapViewToTZ
                                    .border(Color.white)
                                    .frame(width: 360, height: 220)
                                    .cornerRadius(10)
                                    .padding()
                                    .shadow(color: Color.gray, radius: 3)
                            }
                        }
                        .onAppear {
                            if toTransitionZone != nil {
                                print("3 CONFIRM onAppear")
                                loadMap(for: initialSelectedRoom, on: mapViewFromTZ)
                                mapViewFromTZ.changeColorOfNode(nodeName: "TransitionZone_" + fromTransitionZone!.name, color: .red)
                                loadMap(for: selectedRoom, on: mapViewToTZ)
                                mapViewToTZ.changeColorOfNode(nodeName: "TransitionZone_" + toTransitionZone!.name, color: .red)
                            }
                        }
                    }
                }
                
                if (step == 1 && fromTransitionZone != nil) || (step == 2 && toTransitionZone != nil) {
                    Spacer()
                    Button(action: {
                        if step == 1 {
                            step = 2
                            selectedFloor = nil
                            selectedRoom = nil
                        } else if step == 2 {
                            step = 3
                        }
                    }){
                        HStack {
                            Text("Next").bold()
                            Image(systemName: "arrow.right").bold()
                        }
                        .frame(width: 160, height: 60)
                        .foregroundStyle(.white)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(20)
                        .bold()
                    }
                }
                
                if step == 3 {
                    Spacer()
                    Button(action: {
                        //createConnection()
                        showConfirmDialog = true
                    }) {
                        Text("Confirm Connection")
                            .frame(width: 190, height: 60)
                            .foregroundStyle(.white)
                            .background(Color(red: 62/255, green: 206/255, blue: 76/255).opacity(0.9))
                            .cornerRadius(20)
                            .bold()
                    }
                    .confirmationDialog("Do you confirm this connection?", isPresented: $showConfirmDialog) {
                        Button("Confirm") {
                            createConnection()
                            initialSelectedRoom?.debugConnectionPrint()
                            dismiss()
                        }
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
                Text("NEW STAIRS FLOORS CONNECTION")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .background(Color.customBackground.ignoresSafeArea())
    }

    private func loadMap(for room: Room?, on mapView: SCNViewContainer) {
        if let room = room {
            mapView.loadRoomPlanimetry(
                room: room,
                borders: true
            )
        }
    }

    func actionSheetFloorButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = building.floors
            .filter { floor in
                if step == 2 {
                    return floor.name != initialSelectedFloor?.name
                }
                return true
            }
            .map { floor in
                .default(Text(floor.name)) {
                    if step == 1 {
                        fromFloor = floor
                    } else {
                        selectedFloor = floor
                    }
                }
            }
        buttons.append(.cancel())
        return buttons
    }
    
    func actionSheetRoomButtons() -> [ActionSheet.Button] {
        guard let rooms = selectedFloor?.rooms else {
            return [.cancel()]
        }
        
        var buttons: [ActionSheet.Button] = rooms
            .filter { room in
                if step == 2 {
                    return room.name != fromRoom?.name
                }
                return true
            }
            .map { room in
                .default(Text(room.name)) {
                    if step == 1 {
                        fromRoom = room
                    } else {
                        selectedRoom = room
                    }
                }
            }
        buttons.append(.cancel())
        return buttons
    }
    
    func actionSheetTZButtons() -> [ActionSheet.Button] {
        guard let transitionZones = selectedRoom?.transitionZones else {
            return [.cancel()]
        }
        
        var buttons: [ActionSheet.Button] = transitionZones.map { tz in
            .default(Text(tz.name)) {
                if step == 1 {
                    
                    mapViewFromTZ.changeColorOfNode(nodeName: "TransitionZone_" + tz.name , color: .red)
                    fromTransitionZone = tz
                } else {
                    mapViewFromTZ.changeColorOfNode(nodeName: "TransitionZone_" +  tz.name , color: .red)
                    toTransitionZone = tz
                }
            }
        }
        buttons.append(.cancel())
        return buttons
    }
    
    private func createConnection() {
        print("Entrato")
        guard let fromTransitionZone = fromTransitionZone,
              let toTransitionZone = toTransitionZone,
              let selectedRoom = selectedRoom
        else {
            print("Missing data for creating the connection")
            return
        }
        
        initialSelectedRoom!.addConnection(from: fromTransitionZone, to: selectedRoom, targetTransitionZone: toTransitionZone)
        
        print("Connection created between \(fromTransitionZone.name) in room \(initialSelectedRoom!.name) and \(toTransitionZone.name) in room \(selectedRoom.name).")
        
    }

}

struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        
        return AddStairsConnectionView(building: building, initialSelectedFloor: floor, initialSelectedRoom: room)
    }
}
