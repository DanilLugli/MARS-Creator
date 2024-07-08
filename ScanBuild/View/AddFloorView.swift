//
//  AddFloorView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 07/07/24.
//

import Foundation
import SwiftUI

struct AddFloorView: View {
    @State private var floorName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var buildingsModel = BuildingModel.getInstance()
    
    var selectedBuilding: UUID
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Insert the name of new floor: ")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                TextField("Floor Name", text: $floorName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
                
                Button(action: {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .none
                    let currentDate = dateFormatter.string(from: Date())
                    
                    let newFloor = Floor(name: floorName, fileURL: URL(fileURLWithPath: ""), idBuilding: UUID(), date: currentDate )
                    buildingsModel.addFloorToBuilding(buildingId: selectedBuilding, floor: newFloor)
                    self.presentationMode.wrappedValue.dismiss()
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
            .padding()
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADD NEW FLOOR")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            print("Info button tapped")
                        }) {
                            Image(systemName: "info.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 31, height: 31)
                                .foregroundColor(.blue) // Simbolo blu
                                .background(Circle().fill(Color.white).frame(width: 31, height: 31))
                        }
                    }
                }
            }
        }
    }
}

struct AddFloorView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuildingIndex = buildingModel.initTryData()
        return AddFloorView(selectedBuilding: firstBuildingIndex).environmentObject(buildingModel)
    }
}
