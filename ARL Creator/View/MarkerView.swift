//
//  MarkerView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import SwiftUI

struct MarkerView: View {
    @ObservedObject var room: Room
    @State private var searchText: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil // Marker selezionato
    @State private var isMarkerDetailSheetPresented = false // Stato per mostrare la sheet
    
    var filteredMarker: [ReferenceMarker] {
        if searchText.isEmpty {
            return room.referenceMarkers
        } else {
            return room.referenceMarkers.filter { $0.imageName.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack {
            if room.referenceMarkers.isEmpty {
                Text("Add Marker to \(room.name) with + icon.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 50) {
                        ForEach(filteredMarker, id: \.id) { marker in
                            Button(action: {
                                selectedMarker = marker // Imposta il marker selezionato
                                isMarkerDetailSheetPresented = true // Mostra la sheet
                            }) {
                                MarkerCardView(imageName: marker)
                            }
                        }
                    }
                }
                .padding(.top, 15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
        .sheet(isPresented: $isMarkerDetailSheetPresented) {
            if let marker = selectedMarker {
                MarkerDetailView(marker: marker)
            }
        }
    }
}

import SwiftUI

struct MarkerDetailView: View {
    @ObservedObject var marker: ReferenceMarker
    @Environment(\.dismiss) private var dismiss // Ambiente per chiudere la sheet
    
    @State private var newName: String
    @State private var newSize: String
    
    init(marker: ReferenceMarker) {
        self.marker = marker
        _newName = State(initialValue: marker.imageName) // Mostra il nome attuale
        _newSize = State(initialValue: "\(marker.physicalWidth)") // Mostra la dimensione attuale
    }
    
    var body: some View {
        ZStack{
            Color.customBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack{
                Text("Marker Details")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top)
                
                if marker.physicalWidth == 0.0{
                    Text("Marker can't have a 0.0 value of Width !")
                        .bold()
                        .foregroundColor(.red)
                        .padding()
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name:")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                    TextField("Enter marker name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.customBackground) // Colore dei caratteri nella TextField
                        .padding(.bottom)
                    
                    Text("Size:")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                    TextField("Enter marker size", text: $newSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .foregroundColor(.customBackground) // Colore dei caratteri nella TextField
                        .padding(.bottom)
                }
                .padding(.horizontal)
                
                Button(action: saveChanges) {
                    Text("Save")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        
    }
    
    private func saveChanges() {
        marker.imageName = newName
        if let size = Double(newSize) {
            marker.physicalWidth = CGFloat(size)
        }
        dismiss() // Chiude la sheet
    }
}
