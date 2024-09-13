//
//  MoveObject.swift
//  ScanBuild
//
//  Created by Danil Lugli on 13/09/24.
//

import Foundation

protocol MoveObject {
    func moveUp()
    func moveDown()
    func moveLeft()
    func moveRight()
    
    func rotateClockwise()
    func rotateCounterClockwise()
}
