//
//  FloorPlanimetryTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/01/25.
//

import SwiftUI
struct FloorPlanimetryView: View {
    @ObservedObject var floor: Floor
    @Binding var showFloorMap: Bool
    
    var body: some View {
        VStack {
            if floor.scene == nil {
                HStack {
                    Text("Create planimetry with")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Image(systemName: "plus.circle")
                        .foregroundColor(.gray)
                    Text("icon inside")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            } else {
                VStack {
                    if floor.scene == nil {
                        ProgressView("Uploading planimetry...")
                    } else {
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                                Toggle(isOn: $showFloorMap) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.customBackground)
                                        Text("Show rooms positions")
                                            .font(.system(size: 20))
                                            .bold()
                                            .foregroundColor(Color.customBackground)

                                    }
                                }
                                .toggleStyle(SwitchToggleStyle())
                                .padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .padding()

                            ZStack {
                                if showFloorMap {
                                    floor.planimetryRooms
                                        .border(Color.white)
                                        .cornerRadius(10)
                                        .padding()
                                        .shadow(color: Color.gray, radius: 3)
                                        .onAppear {
                                            floor.planimetryRooms.handler.showAllRooms(floor: floor)
                                        }
                                } else {
                                    floor.planimetry
                                        .border(Color.white)
                                        .cornerRadius(10)
                                        .padding()
                                        .shadow(color: Color.gray, radius: 3)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
