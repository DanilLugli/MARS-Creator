//
//  Extension.swift
//  ScanBuild
//
//  Created by Danil Lugli on 27/11/24.
//

import Foundation
import SwiftUI
import SceneKit
import ComplexModule

extension Color {
    static let customBackground = Color(red: 0x1A / 255, green: 0x37 / 255, blue: 0x61 / 255)
    func toUIColor() -> UIColor {
        let uiColor = UIColor(self)
        return uiColor
    }
}


extension Notification.Name {
    static var genericMessage: Notification.Name {
        return .init(rawValue: "genericMessage.message")
    }
    static var genericMessage2: Notification.Name {
        return .init(rawValue: "genericMessage.message2")
    }
    static var genericMessage3: Notification.Name {
        return .init(rawValue: "genericMessage.message3")
    }
    static var trackingState: Notification.Name {
        return .init(rawValue: "trackingState.message")
    }
    static var timeLoading: Notification.Name {
        return .init(rawValue: "timeLoading.message")
    }
    static var worldMapMessage: Notification.Name {
        return .init(rawValue: "WorldMapMessage.message")
    }
    static var worldMapCounter: Notification.Name {
        return .init(rawValue: "WorldMapMessage.counter")
    }
    
    static var trackingPosition: Notification.Name {
        return .init(rawValue: "trackingPosition.message")
    }
    
    static var worldMapNewFeatures: Notification.Name {
        return .init(rawValue: "worlMapNewFeatures.message")
    }
    
    static var trackingPositionFromMotionManager: Notification.Name {
        return .init(rawValue: "trackingPositionFromMotionManager.message")
    }
    
}

extension SCNQuaternion {
    func difference(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w
        )
    }
    
    func sum(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w
        )
    }
}

extension SCNVector3 {
    func difference(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z
        )
    }
    
    func sum(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z
        )
    }
    
    func rotateAroundOrigin(_ angle: Float) -> SCNVector3 {
        var a = Complex<Float>.i
        a.real = cos(angle)
        a.imaginary = sin(angle)
        var b = Complex<Float>.i
        b.real = self.x
        b.imaginary = self.z
        let position = a*b
        return SCNVector3(
            position.real,
            self.y,
            position.imaginary
        )
    }
}

extension SCNNode {
    
    var height: CGFloat { CGFloat(self.boundingBox.max.y - self.boundingBox.min.y) }
    var width: CGFloat { CGFloat(self.boundingBox.max.x - self.boundingBox.min.x) }
    var length: CGFloat { CGFloat(self.boundingBox.max.z - self.boundingBox.min.z) }
    
    var halfCGHeight: CGFloat { height / 2.0 }
    var halfHeight: Float { Float(height / 2.0) }
    var halfScaledHeight: Float { halfHeight * self.scale.y  }
}


