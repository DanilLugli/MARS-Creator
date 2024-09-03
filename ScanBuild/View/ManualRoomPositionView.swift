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
                
                VStack{
                    HStack{
                        //Left And Right
                        HStack {
                            Button(action: {
                                mapPositionView.handler
                                    .moveRoomPositionRight()
                            }) {
                                Image(systemName: "arrow.right")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                            
                            Button(action: {
                                mapPositionView.handler.moveRoomPositionLeft()
                            }) {
                                Image(systemName: "arrow.left")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                        }.padding()
                        //Up And Down
                        HStack {
                            Button(action: {
                                mapPositionView.handler.moveRoomPositionUp()
                            }) {
                                Image(systemName: "arrow.down")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                            
                            Button(action: {
                                mapPositionView.handler.moveRoomPositionDown()
                            }) {
                                Image(systemName: "arrow.up")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                        }.padding()
                        //Clock
                        HStack {
                            Button(action: {
                                mapPositionView.handler.rotateClockwise()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                            
                            Button(action: {
                                mapPositionView.handler.rotateCounterClockwise()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.bordered)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                        }.padding()
                    }
                    Spacer()
                }.padding(.top)
            }.onAppear {
                    var roomURLs: URL
                    roomURLs = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                    mapPositionView.handler.loadRoomMapsPosition(
                        floor: floor,
                        roomURL: roomURLs,
                        borders: true
                    )
                }
            
            Button(action: {
                floor.updateAssociationMatrixInJSON(for: room.name, fileURL: floor.floorURL.appendingPathComponent("\(floor.name).json"))
                floor.objectWillChange.send()  // Forza RoomView a rilevare il cambiamento
                showUpdateAlert = true
            }) {
                Text("Save Position")
                    .bold()
                    .foregroundColor(.white)
            }
            .buttonStyle(.bordered)
            .background(Color.blue.opacity(0.6))
            .cornerRadius(8)
            .padding()
            
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("POSITIONING ROOM")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text("Room Position Saved"),
                dismissButton: .default(Text("OK")){
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
