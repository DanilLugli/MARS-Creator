//
//  Coordinates.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class Coordinates: Codable {
    var x: Float
    var y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    var getX: Float {
        get {
            return x
        }
    }
    
    var getY: Float {
        get {
            return y
        }
    }
}
