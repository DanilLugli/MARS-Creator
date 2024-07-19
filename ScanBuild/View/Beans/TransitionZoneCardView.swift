//
//  TransitionZoneCardView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation
import SwiftUI

//struct TransitionZoneCardView: View {
//    var xMin: Double
//    var xMax: Double
//    var yMin: Double
//    var yMax: Double
//    var rowSize: Int
//    
//    init(transitionZone: TransitionZone, rowSize: Int = 1) {
//        self.xMin = transitionZone.xMin
//        self.xMax = transitionZone.xMax
//        self.yMin = transitionZone.yMin
//        self.yMax = transitionZone.yMax
//        self.rowSize = rowSize
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("xMin: \(xMin), xMax: \(xMax)")
//                .font(.system(size: 20, weight: .bold))
//                .foregroundColor(.black)
//            
//            Text("yMin: \(yMin), yMax: \(yMax)")
//                .font(.system(size: 14))
//                .foregroundColor(.gray)
//        }
//        .padding()
//        .frame(width: 330/CGFloat(rowSize), height: 80)
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
//        .padding([.leading, .trailing], 10)
//    }
//}
//
//struct TransitionZoneCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransitionZoneCardView(transitionZone: TransitionZone(name:"A", xMin: 1.0, xMax: 5.0, yMin: 2.0, yMax: 6.0), rowSize: 3)
//    }
//}
