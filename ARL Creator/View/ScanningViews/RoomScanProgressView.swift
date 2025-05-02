//
//  RoomScanProgressView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 19/02/25.
//

import SwiftUI

struct RoomScanProgressView: View {
    @State private var progress: CGFloat = 0.0  
    
    let maxDistance: CGFloat = 22.0
    let maxObjects: Int = 45
    let maxFeatures: Int = 9000
    
    var scannedDistance: CGFloat
    var detectedObjects: Int
    var featuresPoint: Int?
    
    var progressColor: Color {
        switch progress {
        case 0.0..<0.6: return .green
        case 0.6..<0.9: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack {
            Text("Scanning Progress").padding(.top).font(.system(size: 18, weight: .bold, design: .default))
            ProgressView(value: progress)
                               .progressViewStyle(LinearProgressViewStyle())
                               .tint(progressColor)
                               .frame(height: 16)
                               .padding(.horizontal)

            
        }.background(Color.white)
        .cornerRadius(20)
        .padding(.horizontal)
        .onAppear {
            updateProgress()
        }
        .onChange(of: scannedDistance) { _, _ in updateProgress() }
        .onChange(of: detectedObjects) { _, _ in updateProgress() }
        .onChange(of: featuresPoint) { _, _ in updateProgress() }
    }
    
    @State var maxDistanceProgress: CGFloat = 0.0
    @State var maxObjectsProgress: CGFloat = 0.0
    @State var maxFeaturesProgress: CGFloat = 0.0
    
    private func updateProgress() {
        let currentDistanceProgress = min(scannedDistance / maxDistance, 1.0)
        let currentObjectsProgress = min(CGFloat(detectedObjects) / CGFloat(maxObjects), 1.0)
        let currentFeaturesProgress = min(CGFloat(featuresPoint ?? 0) / CGFloat(maxFeatures), 1.0)

        
        maxDistanceProgress = max(maxDistanceProgress, currentDistanceProgress)
        maxObjectsProgress = max(maxObjectsProgress, currentObjectsProgress)
        maxFeaturesProgress = max(maxFeaturesProgress, currentFeaturesProgress)

        progress = max(maxDistanceProgress, maxObjectsProgress, maxFeaturesProgress)
        
        print("DEBUG: Progress aggiornato -> \(progress * 100)% (D:\(maxDistanceProgress), O:\(maxObjectsProgress), F:\(maxFeaturesProgress))")
    }
}
