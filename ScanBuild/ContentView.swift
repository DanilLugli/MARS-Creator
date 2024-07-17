//
//  ContentView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView().frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity).edgesIgnoringSafeArea(.all).background(Color.customBackground)
    }
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView()
    }
}
