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
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("\(dateFormatter.string(from: date))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            
        }
        .frame(width: 330/CGFloat(rowSize), height: 80)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding([.leading, .trailing], 10)
    }
}

struct DefaultCardView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCardView(name: "1", date: Date(), rowSize: 3, isSelected: true)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
