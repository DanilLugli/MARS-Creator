import SwiftUI
import Foundation

struct AddBuildingView: View {
    @State private var buildingName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var buildingsModel = BuildingModel.getInstance()

    var body: some View {
        NavigationStack {
            VStack {
                Text("Insert the name of new building: ")
                    .font(.system(size: 18))
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                        .foregroundColor(.white) // Colore bianco
                TextField("Building Name", text: $buildingName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
                
                // Pulsante di salvataggio
                Button(action: {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .none
                    _ = dateFormatter.string(from: Date())
                    
                    let newBuilding = Building(name: buildingName, lastUpdate: Date(), floors: [], buildingURL: URL(fileURLWithPath: "") )
                    buildingsModel.addBuilding(building: newBuilding)
                    self.presentationMode.wrappedValue.dismiss() // Torna alla schermata precedente
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
            .navigationTitle("Add New Building")
        }
    }
}

struct AddBuildingView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        AddBuildingView().environmentObject(buildingModel)
    }
}
