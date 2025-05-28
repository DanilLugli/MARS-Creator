import SwiftUI

struct ConnectionCardView: View {
    var name: String
    var date: Date?
    var isSelected: Bool
    var isFloor: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            
            VStack(alignment: .leading) {
                if isFloor{
                    Text("Floor")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .fontDesign(.rounded)
                }
                else{
                    Text("Room")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .fontDesign(.rounded)
                }
                
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.primaryText)
                    .padding(.top, 2)
                    .fontDesign(.rounded)
                
                if let date = date {
                    Text("\(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top)
                        .fontDesign(.rounded)
                }
            }
            .padding()
        }
        .frame(width: 90, height: 80)  // Dimensione fissa per evitare lo schiacciamento
        .cornerRadius(10)
        //.shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ConnectionCardView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionCardView(name: "Room", date: nil, isSelected: true, isFloor: true)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

