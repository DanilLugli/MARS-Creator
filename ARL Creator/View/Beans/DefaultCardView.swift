import Foundation
import SwiftUI

struct DefaultCardView: View {
    var name: String
    var date: Date
    var rowSize: Int
    var isSelected: Bool
    
    init(name: String, date: Date, rowSize: Int = 1, isSelected: Bool = false) {
        self.name = name
        self.date = date
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
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.customBackground)
                        
                        Text("Last modified: \(dateFormatter.string(from: date))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                    }
                    Spacer()
                }.padding(.leading)
            }
            .frame(width: geometry.size.width / CGFloat(rowSize), height: 80)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

        }
    }
}

struct DefaultCardView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCardView(name: "Room", date: Date(), rowSize: 1, isSelected: true)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
