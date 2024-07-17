//
//  MatrixView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 11/07/24.
//
import Foundation
import SwiftUI

struct MatrixView: View {
    
    @State private var selectedGlobal: String = ""
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    
    // Lista hard coded di oggetti
    let items = ["Muri", "Sedie", "Porte", "Tavoli"]
    
    var body: some View {
        NavigationStack {
            //            VStack {
            //                Text("CREATE MATRIX")
            //                    .font(.system(size: 14))
            //                    .fontWeight(.heavy)
            //                ConnectedDotsView(labels: ["1° Relation", "2° Relation", "3° Relation"], progress: 3).padding()
            //                Text("Choose Global ")
            //                    .font(.system(size: 22))
            //                    .fontWeight(.heavy)
            //                ScrollView(.horizontal, showsIndicators: false) {
            //                    HStack {
            //                        ForEach(items, id: \.self) { item in
            //                            Text(item)
            //                                .padding()
            //                                .background(Color.gray.opacity(0.2))
            //                                .cornerRadius(8)
            //                        }
            //                    }
            //                }
            //
            //                if let selectedGlobalItem = selectedFloor {
            //                    VStack{
            //                        Divider()
            //                        Text("Choose Local") .font(.system(size: 22))
            //                            .fontWeight(.heavy)
            //                        ScrollView(.horizontal, showsIndicators: false){
            //                            HStack {
            //                                ForEach(buildingsModel.getRooms(byFloorId: selectedFloorId)) { room in
            //                                    DefaultCardView(name: room.name, date: room.date, rowSize: 2).onTapGesture {
            //                                        selectedRoom = room.id
            //                                    }
            //                                }
            //                            }
            //                        }
            //                    }.padding()
            //
            //                }
            //
            //                if selectedTransitionZone != nil {
            //                    Spacer()
            //                    Button(action: {
            //                        if fromTransitionZone != nil {
            //                            buildingsModel.createConnection(buildingId: selectedBuilding, zone1: buildingsModel.getTransitionZoneById(selectedTransitionZone!)!, zone2: buildingsModel.getTransitionZoneById(fromTransitionZone!)!)
            //                            showAlert = true
            //                            dismiss()
            //                        } else {
            //                            fromTransitionZone = selectedTransitionZone
            //                            fromFloor = selectedFloor
            //                        }
            //
            //                        selectedTransitionZone = nil
            //                        selectedRoom = nil
            //                        selectedFloor = nil
            //                    }) {
            //                        Text(fromTransitionZone == nil ? "SELECT START" : "SAVE")
            //                            .font(.system(size: 22, weight: .heavy))
            //                            .foregroundColor(.white)
            //                            .frame(maxWidth: .infinity, alignment: .bottom)
            //                            .padding()
            //                            .background(Color.blue)
            //                            .cornerRadius(10)
            //                    }
            //                    .padding(.horizontal, 20)
            //                    .padding(.bottom, 20)
            //                }
            //            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).background(Color.customBackground).foregroundColor(.white)
            //        }
            //        .toolbar {
            //            ToolbarItem(placement: .principal) {
            //                Text("NEW MATRIX")
            //                    .font(.system(size: 22, weight: .heavy))
            //                    .foregroundColor(.white)
            //            }
            //            ToolbarItem(placement: .navigationBarTrailing) {
            //                HStack {
            //                    Button(action: {
            //                        // Azione per il pulsante "info.circle"
            //                        print("Info button tapped")
            //                    }) {
            //                        Image(systemName: "info.circle")
            //                            .foregroundColor(.white)
            //                            .padding(8)
            //                            .frame(width: 30, height: 30)
            //                            .background(Color.blue)
            //                            .clipShape(Circle())
            //                    }
            //                }
            //            }
            //        }
            //        .background(Color.customBackground.ignoresSafeArea())
            //    }
        }
    }
    
    
    struct MatrixView_Preview: PreviewProvider {
        static var previews: some View {
            let buildingModel = BuildingModel.getInstance()
            let firstBuildingIndex = buildingModel.initTryData()
            return MatrixView().environmentObject(buildingModel)
        }
    }
}
