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
    
    @State var mapTransitionView = SCNViewTransitionZoneContainer()
    
    var body: some View{
        VStack{
            // Text per il nome della Transition Zone
            Text("Insert the name of the Transition Zone")
                .font(.headline)
                .padding(.top)
            
            // TextField per inserire il nome della Transition Zone
            TextField("Transition Zone Name", text: $transitionZoneName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing, .bottom])
            
            ZStack{
                mapTransitionView
                    .border(Color.white)
                    .cornerRadius(10)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
            }.onAppear {
                mapTransitionView.loadRoomMaps(room: room, borders: true, usdzURL: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz"))
            }
            
            Button(action: {
                // Controlla se il nome della Transition Zone è stato inserito
                guard !transitionZoneName.isEmpty else {
                    // Se il nome non è inserito, mostra un alert o un messaggio (opzionale)
                    showUpdateAlert = true
                    return
                }
                
                // Aggiungi la Transition Zone con il nome specificato alla scena
                addTransitionZoneToScene()
                
                // Mostra un alert di conferma
                showUpdateAlert = true
            }) {
                Text("Save Transition Zone")
                    .bold()
                    .foregroundColor(.white)
            }
            .font(.system(size: 20))
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
        }
        .background(Color.customBackground)
        .foregroundColor(.white)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                    floor.objectWillChange.send()
                }
            )
        }
    }

    private func addTransitionZoneToScene() {
        // Aggiungi alla logica della stanza (Room) e salva il nome della Transition Zone
        let transitionZone = TransitionZone(name: transitionZoneName, connection: Connection(name: ""))
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
