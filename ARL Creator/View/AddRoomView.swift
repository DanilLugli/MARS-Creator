import Foundation
import SwiftUI

struct AddRoomView: View {
    
    @State private var roomName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var floor: Floor
   
    var body: some View {
        VStack {
            Text("Insert the name of new room: ")
                .font(.system(size: 18))
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .foregroundColor(.white)
            
            TextField("Room Name", text: $roomName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            Spacer()
            
            Button(action: {
                let newRoom = Room(
                    _name: roomName,
                    _lastUpdate: Date(),
                    _planimetry: SCNViewContainer(),
                    _referenceMarkers: [],
                    _transitionZones: [],
                    _sceneObjects: [],
                    _roomURL: URL(fileURLWithPath: "")
                )
                
                floor.addRoom(room: newRoom)
                
                presentationMode.wrappedValue.dismiss()
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
        .navigationTitle("Add New Room")
    }
}

struct AddRoomView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuilding = buildingModel.initTryData()
        let firstFloor = firstBuilding.floors.first!
       
        return AddRoomView(floor: firstFloor)
    }
}
