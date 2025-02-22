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
import AlertToast


struct ManualRoomPositionView: View {
    
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State private var showFornitures = false
    
    @State private var showSaveMatrixToast = false
    
    @State var mapPositionView = SCNViewUpdatePositionRoomContainer()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View{
        VStack{
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                Toggle(isOn: $showFornitures){
                    HStack {
                        Image(systemName: "table.furniture")
                            .font(.system(size: 20))
                            .foregroundColor(Color.customBackground)
                        Text("Show Fornitures")
                            .font(.system(size: 20))
                            .bold()
                            .foregroundColor(Color.customBackground)
                    }
                }
                .padding()
                .bold()
                .onChange(of: showFornitures) { newValue in
                    mapPositionView.handler.loadRoomMapsPosition(
                        floor: floor,
                        room: room,
                        fornitures: newValue
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 40)
            .padding()
            
            
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
                    mapPositionView.handler.loadRoomMapsPosition(
                        floor: floor,
                        room: room,
                        fornitures: false
                    )
                
                floor._associationMatrix[room.name] = RoomPositionMatrix(name: room.name, translation: matrix_identity_float4x4, r_Y: matrix_identity_float4x4)
                floor.addIdentityMatrixToJSON(to: floor.floorURL.appendingPathComponent("\(floor.name).json"), for: floor, roomName: room.name)
                }
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationTitle("Positioning \(room.name)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    
                    if !floor.isRoomPositionMatrixInJSON(fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"), roomName: room.name){
                        
                        floor.addIdentityMatrixToJSON(to: floor.floorURL.appendingPathComponent("\(floor.name).json"), for: floor, roomName: room.name)
                        
                    }
                    
                    floor.updateAssociationMatrixInJSON(for: room.name, fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"))

                    floor.planimetryRooms.handler.loadRoomsMaps(
                        floor: floor,
                        rooms: floor.rooms
                    )
                    
                    floor.getRoomByName(room.name)?.hasPosition = true
                    
                    showSaveMatrixToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))  
                        .foregroundStyle(.white, .green, .green)
                }
            }
        }.toast(isPresenting: $showSaveMatrixToast){
            AlertToast(type: .complete(Color.green), title: "Room position saved successfully ")
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
