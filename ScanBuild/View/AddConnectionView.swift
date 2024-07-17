import SwiftUI
import Foundation

struct AddConnectionView: View {
    
    var selectedBuilding: UUID
    @State private var buildingName: String = ""
    @State private var selectedFloor: UUID? = nil
    @State private var selectedRoom: UUID? = nil
    @State private var fromFloor: UUID? = nil
    @State private var selectedTransitionZone: UUID? = nil
    @State private var fromTransitionZone: UUID? = nil
    @State private var showAlert: Bool = false

    
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var buildingsModel = BuildingModel.getInstance()

    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(buildingsModel.getBuildingById(selectedBuilding)?.name ?? "Unknown") > New Connection")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                ConnectedDotsView(labels: ["1° T.Z.", "2° T.Z."], progress: fromTransitionZone == nil ? 1 : 2 ).padding()
                Text("Choose Floor") .font(.system(size: 22))
                    .fontWeight(.heavy)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack {
                        ForEach(buildingsModel.getFloors(byBuildingId: selectedBuilding)) { floor in
                            
                            if floor.id != fromFloor{
                                DefaultCardView(name: floor.name, date: floor.date, rowSize: 2)
                                    .onTapGesture {
                                        selectedFloor = floor.id
                                    }
                            }
                        }
                    }
                }
                
                if let selectedFloorId = selectedFloor {
                    VStack{
                        Divider()
                        Text("Choose Room") .font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack {
                                ForEach(buildingsModel.getRooms(byFloorId: selectedFloorId)) { room in
                                    DefaultCardView(name: room.name, date: room.date, rowSize: 2).onTapGesture {
                                        selectedRoom = room.id
                                    }
                                }
                            }
                        }
                    }.padding()

                }
                
                if let selectedRoomId = selectedRoom {
                    VStack{
                        Divider()
                        
                        Text("Choose Transition Zone") .font(.system(size: 22))
                            .fontWeight(.heavy)
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack {
                                ForEach(buildingsModel.getTransitionZones(byRoomId: selectedRoomId)) { transitionZone in
                                    TransitionZoneCardView(transitionZone: transitionZone, rowSize: 2).onTapGesture {
                                        selectedTransitionZone = transitionZone.id
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
                            buildingsModel.createConnection(buildingId: selectedBuilding, zone1: buildingsModel.getTransitionZoneById(selectedTransitionZone!)!, zone2: buildingsModel.getTransitionZoneById(fromTransitionZone!)!)
                            showAlert = true
                            dismiss()
                        } else {
                            fromTransitionZone = selectedTransitionZone
                            fromFloor = selectedFloor
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
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Color.customBackground).foregroundColor(.white)
                .alert(isPresented: $showAlert){
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
                            .foregroundColor(.blue) // Simbolo blu
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
}


struct AddConnection_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        return AddConnectionView(selectedBuilding: firstBuildingIndex).environmentObject(buildingModel)
    }
}
