//
//  ScanningCard.swift
//  ScanBuild
//
//  Created by Danil Lugli on 22/07/24.
//

import Foundation
import SwiftUI


struct ScanningCardView: View {
    
    var messagesFromWorldMap: String
    var newFeatures: Int?
    var onSave: () -> Void
    var onRestart: () -> Void
    var saveMap: () -> Void
    
    var stateScanning: Bool = true
    
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
                HStack{
                    
                    Button(action: {
                        onRestart()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        onSave()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.green)
                    }
                }

            }
            .padding()
            .frame(width: 380, height: 125)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(20)
    }
}

struct ScanningCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Esempio con newFeatures e stato attivo
            ScanningCardView(
                messagesFromWorldMap: "Scan completed successfully!",
                newFeatures: 3,
                onSave: {
                    print("Save button tapped!")
                },
                onRestart: {
                    print("Restart tapped!")
                },
                saveMap: {
                    print("Save map tapped!")
                },
                stateScanning: false // Stato attivo
            )
            .previewLayout(.sizeThatFits)
            .padding()

            // Esempio senza newFeatures e stato inattivo
            ScanningCardView(
                messagesFromWorldMap: "No new features detected.",
                newFeatures: nil,
                onSave: {
                    print("Save button tapped!")
                },
                onRestart: {
                    print("Restart tapped!")
                },
                saveMap: {
                    print("Save map tapped!")
                },
                stateScanning: false // Stato inattivo
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
