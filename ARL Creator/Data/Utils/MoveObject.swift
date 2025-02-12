//
//  MoveObject.swift
//  ScanBuild
//
//  Created by Danil Lugli on 13/09/24.
//

import Foundation

protocol MoveObject {
    // I metodi di movimento ora ricevono un parametro 'continuous'
    // Se true viene eseguito uno step maggiore (per pressione continua)
    // Se false viene eseguito uno step normale (tap singolo)
    func moveUp(continuous: Bool)
    func moveDown(continuous: Bool)
    func moveLeft(continuous: Bool)
    func moveRight(continuous: Bool)
    
    // Anche la rotazione può essere gestita in modo analogo, se necessario.
    // Se non serve differenziare il comportamento, puoi anche mantenere le versioni senza parametro.
    func rotateClockwise()
    func rotateCounterClockwise()
}
