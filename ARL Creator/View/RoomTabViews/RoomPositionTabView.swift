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

    var body: some View {
        VStack {
            if doesMatrixExist(for: room.name, in: floor.associationMatrix) {
                VStack {
                    ZStack {
                        floor.planimetryRooms
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                            .onAppear {
                                floor.planimetryRooms.handler.showOnlyRoom(named: room.name, in: floor)
                            }
                    }
                }
            } else {
                HStack {
                    Text("Create Position with")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Image(systemName: "plus.circle")
                        .foregroundColor(.gray)
                    
                    Text("icon")
                        .foregroundColor(.gray)
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}
