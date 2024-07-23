import Foundation
import SwiftUI

struct AddRoomView: View {
    
    @State private var roomName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State var floor: Floor

    var body: some View {
        NavigationStack {
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
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .none
                    let currentDate = dateFormatter.string(from: Date())
                    
                    let newRoom = Room(name: roomName, lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                    
                    floor.addRoom(room: newRoom)
                    
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
                    Text("ADD NEW ROOM")
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
                                .foregroundColor(.blue)
                                .background(Circle().fill(Color.white).frame(width: 31, height: 31))
                        }
                    }
                }
            }
        }
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
