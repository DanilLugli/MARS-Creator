import SwiftUI

struct ConnectionCardView: View {
    var name: String
    var date: Date?
    var isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.green : Color.clear, lineWidth: 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                
                // Gestione della data opzionale
                if let date = date {
                    Text("\(dateFormatter.string(from: date))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                } 
            }
            .padding()
        }
        .frame(width: 100, height: 80)  // Dimensione fissa per evitare lo schiacciamento
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ConnectionCardView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionCardView(name: "Room", date: nil, isSelected: true)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

//struct ConnectionCardListView: View {
//    var cards: [ConnectionCardView]
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack {
//                ForEach(cards.indices, id: \.self) { index in
//                    cards[index]
//                        .padding(.horizontal, 5) // Adding some horizontal padding between cards
//                }
//            }
//            .padding() // Adding some padding to the entire HStack
//        }
//    }
//}
//
//struct ConnectionCardListView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConnectionCardListView(cards: [
//            ConnectionCardView(name: "Room 1", date: Date(), isSelected: false),
//            ConnectionCardView(name: "Room 2", date: Date(), isSelected: true),
//            ConnectionCardView(name: "Room 3", date: Date(), isSelected: false)
//        ])
//    }
//}
