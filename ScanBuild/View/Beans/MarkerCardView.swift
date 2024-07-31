//
//  MarkerCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 30/07/24.
//

import SwiftUI

struct MarkerCardView: View {
    
    var name: String
    var rowSize: Int
    
    
    init(name: String, rowSize: Int) {
        self.name = name
        self.rowSize = rowSize
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                VStack(alignment: .leading) {
                    HStack{
                        Text(name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    }
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
    MarkerCardView(name: "La Monnalisa", rowSize: 1)
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
