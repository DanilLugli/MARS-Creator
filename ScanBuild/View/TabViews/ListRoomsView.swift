//
//  ListRoomsView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 22/07/24.
//

import SwiftUI

struct ListRoomsView: View {
   
    var building: Building
    var rooms : [Room]
    var floor : Floor
    
    var body: some View {
        VStack {
            if rooms.isEmpty {
                VStack {
                    Text("Add Room to \(floor.name) with + icon")
                        .foregroundColor(.gray)
                        .font(.headline)
                        .padding()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 50) {
                        ForEach(rooms, id: \.id) { room in
                            NavigationLink(destination: MarkerView(room: room, building: building,   floor: floor)) {
                                DefaultCardView(name: room.name, date: room.lastUpdate).padding()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}


struct ListRoomsView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        
        return ListRoomsView(building: building, rooms: floor.rooms, floor: floor)
    }
}
