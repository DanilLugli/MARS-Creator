//
//  TransitionZone.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation


struct TransitionZone: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var xMin: Double
    var xMax: Double
    var yMin: Double
    var yMax: Double

    init(name: String, xMin: Double, xMax: Double, yMin: Double, yMax: Double) {
        self.name = name
        self.xMin = xMin
        self.xMax = xMax
        self.yMin = yMin
        self.yMax = yMax
    }
}
