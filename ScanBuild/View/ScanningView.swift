//
//  ScanningView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI
import ARKit

struct ScanningView: View {
    var body: some View{
        NavigationStack{
            Text("Scanning View").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.customBackground).foregroundColor(.white)
        }
    }
}

struct ScanningView_Preview: PreviewProvider {
    static var previews: some View{
        ScanningView()
    }
}

