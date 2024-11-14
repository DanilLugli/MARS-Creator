import Foundation
import SwiftUI

struct AddFloorView: View {
    
    @State private var floorName: String = ""
    @Environment(\.dismiss) var dismiss
    @State var building: Building

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
                    _ = dateFormatter.string(from: Date())
                    
                    let newFloor = Floor(
                        _name: floorName,
                        _lastUpdate: Date(),
                        _planimetry: SCNViewContainer(),
                        _planimetryRooms: SCNViewMapContainer(),
                        _associationMatrix: [String : RotoTraslationMatrix](),
                        _rooms: [],
                        _sceneObjects: nil,
                        _scene: nil,
                        _sceneConfiguration: nil,
                        _floorURL: URL(fileURLWithPath: "")
                    )
                    
                    building.addFloor(floor: newFloor)
                    
                    // Chiude la vista corrente per tornare alla vista precedente
                    dismiss()
                    
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
            .navigationTitle("Add New Floor")
        }
    }
}

struct AddFloorView_Preview: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let firstBuilding = buildingModel.initTryData()
        return AddFloorView(building: firstBuilding)
    }
}
