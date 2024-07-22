//
//  ContentView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    init() {
        UITabBar.appearance().backgroundColor = UIColor(red: 1.0, green: 1.0, blue:1.0, alpha: 0.7)
        UITabBar.appearance().unselectedItemTintColor = .darkGray
        UITabBar.appearance().tintColor = .systemBlue
        
        let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                
                // Imposta il colore di sfondo specifico
                appearance.backgroundColor = UIColor(red: 0x1A/255, green: 0x37/255, blue: 0x61/255, alpha: 1.0)

                // Imposta il colore del testo del titolo
                appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

                // Configura l'aspetto degli elementi della barra di navigazione, incluso il bottone "Back"
                let buttonAppearance = UIBarButtonItemAppearance()
                buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
                buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.white]

                // Configura l'aspetto degli elementi della barra di navigazione
                appearance.backButtonAppearance = buttonAppearance
                appearance.buttonAppearance = buttonAppearance
                appearance.doneButtonAppearance = buttonAppearance

                // Applica l'aspetto configurato
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                
                // Imposta il colore del bottone "Back" e della freccia
                UINavigationBar.appearance().tintColor = UIColor.white

                // Configura anche UIBarButtonItem appearance proxy
                let barButtonItemAppearance = UIBarButtonItem.appearance()
                barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
                barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .highlighted)
                barButtonItemAppearance.tintColor = UIColor.white
    }
    
    var body: some View {
        
        HomeView().frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity).edgesIgnoringSafeArea(.all).background(Color.customBackground)
    }
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        ContentView().environmentObject(buildingModel)
    }
}
