//
//  MatrixCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 30/07/24.
//

import SwiftUI

struct ListConnectionCardView: View {
    
    var floor: String
    var room: String
    var transitionZone: String
    var exist: Bool
    var date: Date
    var rowSize: Int
   
    
    init(floor: String, room: String, transitionZone: String, exist: Bool, date: Date, rowSize: Int) {
        self.floor = floor
        self.room = room
        self.transitionZone = transitionZone
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
                    VStack{
                        Text("Connection Created With:").font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                        
                        HStack{
                            Text(floor)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text(" -> ")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text(room)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text(" -> ")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Text(transitionZone)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    Text("\(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 120)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
        }
    }
}


#Preview {
    ListConnectionCardView(floor: "floor", room: "room", transitionZone: "TZ", exist: true, date: Date(), rowSize: 1)
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
