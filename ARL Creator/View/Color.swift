//
//  Color.swift
//  ScanBuild
//
//  Created by Danil Lugli on 05/07/24.
//

import Foundation
import SwiftUI

extension Color {
    static let customBackground = Color(red: 0x1A / 255, green: 0x37 / 255, blue: 0x61 / 255)
    //static let customBackground = Color(red: 0x00 / 255, green: 0xB4 / 255, blue: 0xD8 / 255)
    
    func toUIColor() -> UIColor {
        let uiColor = UIColor(self)
        return uiColor
    }
    
}

