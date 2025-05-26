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
        UITabBar.appearance().backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1.0)
        UITabBar.appearance().unselectedItemTintColor = .darkGray
        UITabBar.appearance().tintColor = .systemBlue
        
        let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                
                // Imposta il colore di sfondo specifico
                appearance.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1.0)
                appearance.shadowColor = .clear // <-- questa rimuove la linea sotto la NavigationBar
                // Imposta il colore del testo del titolo
                appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
                appearance.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]

                // Configura l'aspetto degli elementi della barra di navigazione, incluso il bottone "Back"
                let buttonAppearance = UIBarButtonItemAppearance()
                buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
                buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]

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
                barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], for: .normal)
                barButtonItemAppearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.systemBlue], for: .highlighted)
                barButtonItemAppearance.tintColor = UIColor.systemBlue
    }
    
    var body: some View {
        
        BuildingsView().frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity).edgesIgnoringSafeArea(.all).background(Color.appBackground)
    }
}

struct ContentView_Previews: PreviewProvider{
    static var previews: some View{
        let buildingModel = BuildingModel.getInstance()
        let _ = buildingModel.initTryData()
        ContentView().environmentObject(buildingModel)
    }
}
