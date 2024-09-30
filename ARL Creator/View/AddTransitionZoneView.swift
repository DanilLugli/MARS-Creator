//
//  AddTransitionZoneView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 07/09/24.
//

import SwiftUI

struct AddTransitionZoneView: View {
    @ObservedObject var floor: Floor
    @ObservedObject var room: Room
    
    @State private var transitionZoneName: String = ""
    
    @State private var showUpdateAlert = false
    @State private var showNameErrorAlert = false
    
    @State private var showOptions = false
    @State private var showMenu1 = false
    @State private var showMenu2 = false
    @State private var showMenu3 = false

    @StateObject var viewModel = SCNViewModel()  // Cambiato a ViewModel
    
    
    var body: some View{
        VStack{
            Text("Insert the name of the Transition Zone:")
                .bold()
                .font(.title3)
                .padding(.top)
            
            TextField("Transition Zone Name", text: $transitionZoneName)
                .frame(width: 350, height: 50)
                .foregroundColor(.black)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing, .bottom])
            
            ZStack{
                 SCNViewTransitionZoneContainer(viewModel: viewModel)
                    .border(Color.white)
                    .cornerRadius(10)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
                VStack {
                    Spacer()
                    
                    MapControllerView(moveObject: viewModel)
                        .padding()
                        .background(
                            Color.white.opacity(0.8)
                                
                        )
                        .cornerRadius(10) // BorderRadius
                        .shadow(radius: 4) // Shadow valore 4
                }.padding(26)
                
            }.onAppear {
                viewModel.loadRoomMaps(room: room, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
            }
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    if !transitionZoneName.isEmpty {
                        showUpdateAlert = true
                    }else{
                        showNameErrorAlert = true
                    }
                    
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))  
                        .foregroundStyle(.white, .green, .green)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("ADD TRANSITION ZOOM")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .alert(isPresented: $showUpdateAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text("Are you sure to add and save this Transition Zone?"),
                dismissButton: .default(Text("Yes")){
                    addTransitionZoneToScene()
                    floor.objectWillChange.send()
                }
            )
        }
        .alert(isPresented: $showNameErrorAlert) {
            Alert(
                title: Text("ATTENTION").foregroundColor(.red),
                message: Text("There is no Transition Zone name."),
                dismissButton: .destructive(Text("OK")){
                    showNameErrorAlert = false
                }
            )
        }
    }

    private func addTransitionZoneToScene() {
        
        let transitionZone = TransitionZone(name: transitionZoneName, connection: [Connection(name: "")])
        room.addTransitionZone(transitionZone: transitionZone)
        print("Transition Zone \(transitionZoneName) added to the room and scene.")
    }
}

struct AddTransitionZoneView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        
        return AddTransitionZoneView(floor: floor, room: room)
    }
}



