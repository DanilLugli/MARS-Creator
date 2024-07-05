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
                    let currentDate = dateFormatter.string(from: Date())
                    
                    let newBuilding = Building(name: buildingName, date: currentDate, fileURL: URL(fileURLWithPath: "") )
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADD NEW BUILDING")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        NavigationLink(destination: AddBuildingView()) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 31, height: 31)
                                .foregroundColor(.blue) // Simbolo blu
                                .background(Circle().fill(Color.white).frame(width: 31, height: 31))
                        }
                        Button(action: {
                            // Azione per il pulsante "info.circle"
                            print("Info button tapped")
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(width: 30, height: 30)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }
}

struct AddBuildingView_Previews: PreviewProvider {
    static var previews: some View {
        AddBuildingView()
    }
}
