import Foundation
import SwiftUI

struct ConnectedDotsView: View {
    var labels: [String]
    var dotSize: CGFloat
    var progress: Int
    
    init(labels: [String], dotSize: CGFloat = 14, progress: Int = 1) {
        self.labels = labels
        self.dotSize = dotSize
        self.progress = progress
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(Array(labels.enumerated()), id: \.element) { index, label in
                    HStack {
                        VStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                                .frame(width: dotSize, height: dotSize)
                                .background(
                                    Circle()
                                        .fill(index + 1 <= self.progress ? Color.white : Color.customBackground)
                                )
                            
                            Text(label)
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                        }.frame(height: 34)
                        
                        if index < labels.count - 1 {
                            VStack(alignment: .leading) {
                                Line()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: dotSize, height: 1)
                                    .padding(.top, 8) // Per distanziare la linea dal cerchio
                                Spacer()
                            }.frame(height: 34)                        }
                    }
                }
            }
            .padding([.top, .bottom], 10)
        }
        .padding([.leading, .trailing], 10)
        .frame(maxWidth: .infinity)
        .background(Color.customBackground.ignoresSafeArea())
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

struct ConnectedDotsView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedDotsView(labels: ["Step 1", "Step 2", "Step 3", "Step 4", "Step 5"], progress: 2)
    }
}
