//
//  MatrixCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 30/07/24.
//

import SwiftUI

struct MatrixCardView: View {
    
    var floor: String
    var room: String
    var exist: Bool
    var date: Date
    var rowSize: Int
   
    
    init(floor: String, room: String, exist: Bool, date: Date, rowSize: Int) {
        self.floor = floor
        self.room = room
        self.exist = exist
        self.date = date
        self.rowSize = rowSize
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                
                VStack(alignment: .leading) {
                    HStack{
                        Text(floor)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text(" - ")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text(room)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    HStack{
                        Text("Exist:")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        Text("\(exist)")
                            .font(.system(size: 16, weight: .bold))

                            .foregroundColor(exist ? .green : .red)
                    }
                    Text("\(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding()
                
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 80)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
        }
    }
}


#Preview {
    MatrixCardView(floor: "floor", room: "room", exist: true, date: Date(), rowSize: 1)
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
