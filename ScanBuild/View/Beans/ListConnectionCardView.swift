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
    var targetFloor: String
    var targetRoom: String
    var transitionZone: String
    var exist: Bool
    var date: Date
    var rowSize: Int
   
    
    init(floor: String, room: String, targetFloor: String, targetRoom: String, transitionZone: String, exist: Bool, date: Date, rowSize: Int) {
        self.floor = floor
        self.room = room
        self.targetFloor = targetFloor
        self.targetRoom = targetRoom
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
                        VStack{
                            HStack{
                                Text(floor)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Text(Image(systemName: "arrow.right"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text(room)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            }.padding(.top, -8)
                            
                            Text("Has a connection To:").font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.top, -8)
                            
                            HStack{
                                Text(targetFloor)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Text(Image(systemName: "arrow.right"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text(targetRoom)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Text(Image(systemName: "arrow.right"))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text(transitionZone)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            }.padding(.top, -8)
                        }

                    }
                    Text("Created: \(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 150)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
        }
    }
}


#Preview {
    ListConnectionCardView(floor: "Floor1", room: "Room2", targetFloor: "floor", targetRoom: "room", transitionZone: "TZ", exist: false, date: Date(), rowSize: 1)
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
