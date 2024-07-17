//
//  TransitionZone.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation
import SwiftUI

class TransitionZone {
    private var _id: UUID
    private var _name: String
    private var _connection: Connection?
    private var _transitionArea: Rectangle
    private var _tzJsonURL: URL
    
    init(id: UUID, name: String, connection: Connection?, transitionArea: Rectangle, tzJsonURL: URL) {
        self._id = id
        self._name = name
        self._connection = connection
        self._transitionArea = transitionArea
        self._tzJsonURL = tzJsonURL
    }
    
    var id: UUID {
        get {
            return _id
        }
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var connection: Connection? {
        get {
            return _connection
        }
    }
    
    var transitionArea: Rectangle {
        get {
            return _transitionArea
        }
    }
    
    var tzJsonURL: URL {
        get {
            return _tzJsonURL
        }
    }
    
    static func fromJson(json: String) -> TransitionZone {
        // Implement JSON deserialization logic
        // Placeholder implementation, replace with actual logic
        return TransitionZone(id: UUID(), name: "", connection: nil, transitionArea: Rectangle(), tzJsonURL: URL(string: "https://example.com")!)
    }
    
    func toJson() -> String {
        // Implement JSON serialization logic
    }
    
//    func containsPosition(position: Position) -> Bool {
//        // Implement logic to check if position is within transition area
//    }
//    
//    func createTransitionArea(position: Position, rectangle: Rectangle) -> Rectangle {
//        // Implement logic to create transition area
//    }
    
    func overlapWith(rectangle: Rectangle) {
        // Implement logic to check if overlapping with another rectangle
    }
}
