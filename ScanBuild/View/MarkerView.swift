////
////  MarkerView.swift
////  ScanBuild
////
////  Created by Danil Lugli on 10/07/24.
////
//
//import Foundation
//import SwiftUI
//
//struct MarkerView: View {
//    
//    @State var showRooms: Bool = false
//    @State var room : Room
//    
//    var buildingName: String
//    var floorName: String
//    
//    @State private var searchText: String = ""
//    @State private var isRenameSheetPresented = false
//    @State private var newBuildingName: String = ""
//    @State private var selectedMarker: ReferenceMarker? = nil
//    
//    
//    var body: some View {
//        NavigationStack {
//            VStack{
//                VStack {
//                    Text(!showRooms ? "\(buildingName) > \(floorName) > \(room.name)> Planimetry" : " \(buildingName)  > \(floorName) > \(room.name) > Markers")
//                        .font(.system(size: 14))
//                        .fontWeight(.heavy)
//                    Spacer()
//                    Spacer()
//                    TextField("Search", text: $searchText)
//                        .padding(7)
//                        .background(Color(.systemGray6))
//                        .cornerRadius(8)
//                        .padding(.horizontal, 10)
//                        .frame(width: 180)
//                    
//                    
//                    
//                    ScrollView {
//                        LazyVStack(spacing: 25) {
//                            if !showRooms {
//                                Text("PLANIMETRY").foregroundColor(.white)
//                            } else {
//                                ForEach(filteredMarker, id: \.id) { marker in
//                                    Button(action: {
//                                        selectedMarker = marker
//                                    }) {
//                                        DefaultCardView(name: marker.imageName, date: Date())
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                HStack {
//                    VStack {
//                        Button(action: {
//                            showRooms = false
//                        }) {
//                            Text("\(room.name)")
//                                .fontWeight(.heavy)
//                                .font(.system(size: 20))
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                                .overlay(
//                                    Group {
//                                        if !showRooms {
//                                            RoundedRectangle(cornerRadius: 10)
//                                                .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
//                                        }
//                                    }
//                                )
//                                .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                    .frame(width: 170, height: 60)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//                    .padding([.trailing], 16)
//                    
//                    VStack {
//                        Button(action: {
//                            // Azione del pulsante per impostare showConnection a true
//                            showRooms = true
//                        }) {
//                            Text("MARKERS")
//                                .fontWeight(.heavy)
//                                .font(.system(size: 20))
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                                .overlay(
//                                    Group {
//                                        if showRooms {
//                                            RoundedRectangle(cornerRadius: 10)
//                                                .stroke(Color(red: 0/255, green: 0/255, blue: 100/255, opacity: 1.0), lineWidth: 14)
//                                        }
//                                    }
//                                )
//                                .shadow(color: Color.white.opacity(0.5), radius: 10, x: 0, y: 0)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                    .frame(width: 170, height: 60)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//                    .padding([.trailing], 12)
//                }
//            }.background(Color.customBackground)
//                .foregroundColor(.white)
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .principal) {
//                HStack{
//                    Text("\(room.name)")
//                        .font(.system(size: 26, weight: .heavy))
//                        .foregroundColor(.white)
//                }
//            }
//            ToolbarItem(placement: .navigationBarTrailing) {
//                HStack {
//                    if !showRooms {
//                        NavigationLink(destination: Text("Add Marker View")) {
//                            Image(systemName: "plus.circle.fill")
//                                .font(.system(size: 26))
//                                .foregroundStyle(.white, .blue, .blue)
//                        }
//                        Menu {
//                            Button(action: {
//                                // Azione per il pulsante "Rename"
//                                isRenameSheetPresented = true
//                            }) {
//                                Text("Rename")
//                                Image(systemName: "pencil")
//                            }
//                            Button(action: {
//                                print("Upload Building to Server button tapped")
//                            }) {
//                                Text("Upload Building to Server")
//                                Image(systemName: "icloud.and.arrow.up")
//                            }
//                            Button(action: {
//                                print("Info button tapped")
//                            }) {
//                                Text("Info")
//                                Image(systemName: "info.circle")
//                            }
//                            Button(action: {
//                                print("Delete Building button tapped")
//                            }) {
//                                Text("Delete Building")
//                                Image(systemName: "trash").foregroundColor(.red)
//                            }
//                        } label: {
//                            Image(systemName: "pencil.circle.fill")
//                                .font(.system(size: 26))
//                                .symbolRenderingMode(.palette)
//                                .foregroundStyle(.white, .blue, .blue)
//                        }
//                    } else {
//                        NavigationLink(destination: Text("Add Connection View")) {
//                            Image(systemName: "plus.circle.fill")
//                                .font(.system(size: 26))
//                                .foregroundStyle(.white, .blue, .blue)
//                        }
//                        Menu {
//                            Button(action: {
//                                print("Rename button tapped")
//                            }) {
//                                Text("Rename")
//                                Image(systemName: "pencil")
//                            }
//                            Button(action: {
//                                print("Info button tapped")
//                            }) {
//                                Text("Info")
//                                Image(systemName: "info.circle")
//                            }
//                            Button(action: {
//                                print("Delete Building button tapped")
//                            }) {
//                                Text("Delete")
//                                Image(systemName: "trash")
//                            }
//                        } label: {
//                            Image(systemName: "pencil.circle.fill")
//                                .font(.system(size: 26))
//                                .symbolRenderingMode(.palette)
//                                .foregroundStyle(.white, .blue, .blue)
//                        }
//                    }
//                }
//            }
//        }
//        .sheet(item: $selectedMarker, id: \.id) { marker in
//            VStack {
//                Text("Marker Details")
//                    .font(.system(size: 22))
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 20)
//                    .foregroundColor(.white)
//                Text("Details for \(marker.imageName)")
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
//                Text("Rename Marker")
//                    .font(.system(size: 22))
//                    .fontWeight(.bold)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 20)
//                    .foregroundColor(.white)
//                TextField("New Marker Name", text: $newBuildingName)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(8)
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
//                Spacer()
//                HStack {
//                    Button(action: {
//                        if !newBuildingName.isEmpty {
//                            marker.imageName = $newBuildingName
//                            newBuildingName = ""
//                            selectedMarker = nil
//                        }
//                    }) {
//                        Text("SAVE")
//                            .font(.system(size: 22, weight: .heavy))
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.blue)
//                            .cornerRadius(10)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 20)
//                    
//                    Button(action: {
//                        //TODO: deletereferenceMarker()
//                        selectedMarker = nil
//                    }) {
//                        Text("DELETE")
//                            .font(.system(size: 22, weight: .heavy))
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.red)
//                            .cornerRadius(10)
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 20)
//                }
//            }
//            .padding()
//            .background(Color.customBackground.ignoresSafeArea())
//        }
//    }
//    
//    var filteredMarker: [ReferenceMarker] {
//        if searchText.isEmpty {
//            return room.referenceMarkers
//        } else{
//            return room.referenceMarkers.filter { $0.imageName.lowercased().contains(searchText.lowercased()) }
//        }
//    }
//}
//
//
//struct MarkerView_Previews: PreviewProvider {
//    static var previews: some View {
//        let buildingModel = BuildingModel.getInstance()
//        let building = buildingModel.initTryData()
//        let floor = building.floors.first!
//        let room = floor.rooms.first!
//        
//        return MarkerView(room: room, buildingName: building.name, floorName: floor.name)
//    }
//}
