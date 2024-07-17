//
//  Coordinates.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class Coordinates: Codable {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    var getX: Double {
        get {
            return x
        }
    }
    
    var getY: Double {
        get {
            return y
        }
    }
}
