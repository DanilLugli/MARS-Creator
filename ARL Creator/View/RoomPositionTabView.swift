//
//  RoomPositionTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import SwiftUI

struct RoomPositionTabView: View {
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @State var mapRoomPositionView = SCNViewMapContainer()
    
    var body: some View {
        VStack {
            if doesMatrixExist(for: room.name, in: floor.associationMatrix) {
                VStack {
                    ZStack {
                        mapRoomPositionView
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }
                    .onAppear {
                        let floorRooms: [Room] = [room]
                        mapRoomPositionView.handler.loadRoomsMaps(floor: floor, rooms: floorRooms, borders: true)
                    }
                }
            } else {
                Text("Add & Calculate \(room.name) Position with + icon.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}
