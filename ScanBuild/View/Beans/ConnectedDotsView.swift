//
//  BullettProgressView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation
import SwiftUI

struct ConnectedDotsView: View {
    var dotCount: Int
    var dotSize: CGFloat
    var rowSize: Int
    var progress: Int
    
    init(dotCount: Int, dotSize: CGFloat = 14, rowSize: Int = 1, progress: Int = 0) {
        self.dotCount = dotCount
        self.dotSize = dotSize
        self.rowSize = rowSize
        self.progress = progress
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                        .frame(width: dotSize, height: dotSize)
                        .background(
                            Circle()
                                .fill(index + 1 <= self.progress ? Color.white : Color.customBackground)
                                
                        )
                    
                    if index < dotCount - 1 {
                        Line()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: dotSize, height: 1)
                    }
                }
            }
            .padding()
            .frame(width: 330 / CGFloat(rowSize), height: 80)
            .padding([.leading, .trailing], 10)
            .background(Color.customBackground.ignoresSafeArea())

        }
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
        ConnectedDotsView(dotCount: 5, rowSize: 3, progress: 2)
    }
}
