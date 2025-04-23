import SwiftUI

struct ListConnectionCardView: View {
    var floor: String
    var room: String
    var targetFloor: String
    var targetRoom: String
    var altitudeDifference: Float
    var exist: Bool
    var date: Date
    var rowSize: Int

    init(floor: String, room: String, targetFloor: String, targetRoom: String, altitudeDifference: Float, exist: Bool, date: Date, rowSize: Int) {
        self.floor = floor
        self.room = room
        self.targetFloor = targetFloor
        self.targetRoom = targetRoom
        self.altitudeDifference = altitudeDifference
        self.exist = exist
        self.date = date
        self.rowSize = rowSize
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
            
            VStack(alignment: .leading) {
                VStack {
                    HStack {
                        ConnectionCardView(name: floor, isSelected: false, isFloor: true)
                        
                        Text(Image(systemName: "arrow.right"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                        
                        ConnectionCardView(name: room, isSelected: false, isFloor: false)
                    }
                    .padding(.top, -8)
                    
                    Text("HAS A CONNECTION TO")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.top, 8)
                    
                    HStack {
                        ConnectionCardView(name: targetFloor, isSelected: false, isFloor: true)
                        
                        Text(Image(systemName: "arrow.right"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                        
                        ConnectionCardView(name: targetRoom, isSelected: false, isFloor: false)
                    }
                    .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "Altitude Difference: %.2f", altitudeDifference))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top)
                }

                    
                    Text("Created: \(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                
            }
            .padding()
        }
        .frame(width: 360, height: 345)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ListConnectionCardView(
        floor: "Floor1",
        room: "Room2",
        targetFloor: "Floor3",
        targetRoom: "Room4",
        altitudeDifference: 12.5,
        exist: false,
        date: Date(),
        rowSize: 1
    )
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
