//
//  RoomCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 19/08/24.
//

import SwiftUI

struct RoomCardView: View {
    var name: String
    var date: Date
    var position: Bool
    var color : UIColor?
    var rowSize: Int
    var isSelected: Bool
    
    @State private var showAlert = false
    
    init(name: String, date: Date, position: Bool, color: UIColor, rowSize: Int, isSelected: Bool) {
        self.name = name
        self.date = date
        self.position = position
        self.color = color.withAlphaComponent(0.4)
        self.rowSize = rowSize
        self.isSelected = isSelected
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                HStack{
                    
                    HStack{
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.customBackground)
                            
                            Text("Last modified \(dateFormatter.string(from: date))")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    
                }
                HStack{
                    Spacer()
                    if position == false {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 30))
                            .padding(.trailing) // Regola la posizione
                            .padding(20) // Aggiungi padding per aumentare l'area di tap
                            .onTapGesture {
                                showAlert = true // Mostra l'alert quando premi l'immagine
                            }
                    }else{
                        Image(systemName: "circle.fill")
                            .foregroundColor(Color(color ?? UIColor.white)) // Usa il colore specificato
                            .font(.system(size: 30))
                            .padding(.trailing)
                            .padding(20)
                    }
                }
               
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 80)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("ATTENTION!").foregroundColor(.red),
                    message: Text("\(name) has no position in his Floor.\nYou have to calculate in Room Position page.\n\n(\(name) -> Tab: Room Position -> Add Room Position)"),
                    dismissButton: .default(Text("OK"))
                )
            }
            
        }
    }
}

struct RoomCardView_Previews: PreviewProvider {
    static var previews: some View {
        RoomCardView(name: "Room", date: Date(), position: true, color: UIColor.green, rowSize: 1, isSelected: true)
    }
}
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

