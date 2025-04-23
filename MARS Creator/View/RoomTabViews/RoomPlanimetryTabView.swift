//
//  RoomPlanimetryView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import SwiftUI
import ARKit

struct RoomPlanimetryTabView: View {
    @ObservedObject var room: Room
    @State var roomPlanimetry: SCNViewContainer = SCNViewContainer()

    var body: some View {
        VStack {
            if room.sceneObjects?.count == 0 {
                HStack{
                    Text("Add planimetry with")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Image(systemName: "plus.circle")
                        .foregroundColor(.gray)
                    
                    Text("icon inside ")
                        .foregroundColor(.gray)
                        .font(.headline)
                    
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            } else {
                VStack {
                    ZStack {
                        roomPlanimetry
                            .border(Color.white)
                            .cornerRadius(10)
                            .padding()
                            .shadow(color: Color.gray, radius: 3)
                    }
                }
            }
        }.onAppear{
            roomPlanimetry.loadRoomPlanimetry(room: room, borders: false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}
