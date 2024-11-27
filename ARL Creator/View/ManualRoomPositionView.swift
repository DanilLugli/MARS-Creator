//
//  ManualRoomPositionView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 31/08/24.
//

import SwiftUI
import Foundation
import UIKit
import UniformTypeIdentifiers


struct ManualRoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State private var showUpdateAlert = false
    
    @State var mapPositionView = SCNViewUpdatePositionRoomContainer()
    
    var body: some View{
        VStack{
            ZStack{
                mapPositionView
                    .border(Color.white)
                    .cornerRadius(10)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
                
                VStack {
                    Spacer()
                    
                    MapControllerView(moveObject: mapPositionView.handler)
                        .padding()
                        .background(
                            Color.white.opacity(0.8)
                        )
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }.padding(26)
                
            }.onAppear {
                    let roomURL: URL = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                
                    mapPositionView.handler.loadRoomMapsPosition(
                        floor: floor,
                        roomURL: roomURL,
                        borders: true
                    )
                }
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationTitle("Positioning Room")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    floor.updateAssociationMatrixInJSON(for: room.name, fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                    showUpdateAlert = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))  // Dimensione dell'icona
                        .foregroundStyle(.white, .green, .green)
                }
            }
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text("Room Position Saved"),
                dismissButton: .default(Text("OK")){
                    floor.planimetryRooms.handler.loadRoomsMaps(floor: floor, rooms: floor.rooms, borders: true)
                    floor.objectWillChange.send()
                }
            )
        }
    }
}

struct ManualRoomPositionView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        
        return ManualRoomPositionView(floor: floor, room: room)
    }
}
