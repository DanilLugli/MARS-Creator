//
//  ScanningCard.swift
//  ScanBuild
//
//  Created by Danil Lugli on 22/07/24.
//

import Foundation
import SwiftUI


struct ScanningCardView: View {
    //var worldMapCounter: Int
    var messagesFromWorldMap: String
    var newFeatures: Int?
    var onSave: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                //                Text("WorldMapCounter: \(worldMapCounter)")
                //                    .foregroundColor(.white)
                //                    .font(.system(size: 16, weight: .bold))
                Text(messagesFromWorldMap)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                if let newFeatures = newFeatures {
                    Text("new features: \(newFeatures)")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            Spacer()
            Button(action: {
                onSave()
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
                    
            }
        }
        .padding()
        .frame(width: 380, height: 125)
        .background(Color.blue.opacity(0.4))
        .cornerRadius(20)
    }
}
