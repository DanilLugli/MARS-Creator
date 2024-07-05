import SwiftUI
import Foundation

struct AddConnection: View {
    
    var selectedBuilding: UUID
    @State private var buildingName: String = ""
    @State private var selectedFloor: UUID? = nil
    @State private var selectedRoom: UUID? = nil
    @State private var selectedTransitionZone: UUID? = nil
    @State private var fromTransitionZone: UUID? = nil
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    
    var body: some View {
        NavigationStack {
            
            VStack {
                
                Text("\(buildingsModel.getBuildingById(selectedBuilding)?.name ?? "Unknown") > New Connection")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                ConnectedDotsView(dotCount: 2, progress: fromTransitionZone == nil ? 1 : 2 )
                Text("Choice Floor") .font(.system(size: 22))
                    .fontWeight(.heavy)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack {
                        ForEach(buildingsModel.getFloors(byBuildingId: selectedBuilding)){ floor in
                            DefaultCardView(name: floor.name, date: floor.date, rowSize: 2)
                                .onTapGesture {
                                    selectedFloor = floor.id
                                }
                        }
                    }
                }
                
                if let selectedFloorId = selectedFloor {
                    Divider()
                    Text("Choice Room") .font(.system(size: 22))
                        .fontWeight(.heavy)
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack {
                            ForEach(buildingsModel.getRooms(byFloorId: selectedFloorId)) { room in
                                DefaultCardView(name: room.roomName, date: room.date, rowSize: 2).onTapGesture {
                                    selectedRoom = room.id
                                }
                            }
                        }
                    }
                }
                
                if let selectedRoomId = selectedRoom {
                    
                    Divider()
                    
                    Text("Choice Transition Zone") .font(.system(size: 22))
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
                }
                
                if selectedTransitionZone != nil{
                    Button(action: {
                        if fromTransitionZone != nil {
                            buildingsModel.createConnection(buildingId: selectedBuilding, zone1: buildingsModel.getTransitionZones(byRoomId: selectedTransitionZone!).first!, zone2: buildingsModel.getTransitionZones(byRoomId: fromTransitionZone!).first!)
                            fromTransitionZone = nil
                            selectedTransitionZone = nil
                        } else {
                            fromTransitionZone = selectedTransitionZone
                            selectedTransitionZone = nil
                        }
                    }) {
                        Text("SAVE")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        return AddConnection(selectedBuilding: firstBuildingIndex).environmentObject(buildingModel)
    }
}

