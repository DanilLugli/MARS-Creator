import SwiftUI

struct MarkerView: View {
    @ObservedObject var room: Room
    @State private var searchText: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    
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
                                selectedMarker = marker
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
        .sheet(item: $selectedMarker) { marker in
            MarkerDetailView(marker: marker, room: room)
        }
    }
}

struct MarkerDetailView: View {
    @ObservedObject var marker: ReferenceMarker
    @ObservedObject var room: Room
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newName: String
    @State private var newSize: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var oldName: String
    
    init(marker: ReferenceMarker, room: Room) {
        self.room = room
        self.marker = marker
        self.oldName = marker.imageName
        
        _newName = State(initialValue: marker.imageName)
        _newSize = State(initialValue: "\(marker.physicalWidth)") // Mostra la dimensione attuale
    }
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Marker Details")
                    .font(.title)
                    .bold()
                    .foregroundColor(.customBackground)
                    .padding(.top)
                
                if marker.physicalWidth == 0.0 {
                    Text("Width can't be 0.0")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        )
                        .padding()
                }
                
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "characters.lowercase")
                            .foregroundColor(.customBackground)
                        
                            Text("Name:")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.customBackground)

                        }
                    
                    TextField("Enter marker name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.customBackground)
                        .padding(.bottom)
                    
                    HStack{
                        Image(systemName: "ruler")
                            .foregroundColor(.customBackground)
                        
                        Text("Size (Meters):")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.customBackground)
                    }
                    
                    TextField("Enter marker size", text: $newSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .foregroundColor(.customBackground)
                        .padding(.bottom)
                }
                .padding()
                
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
                .padding(.top)
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .presentationDetents(marker.physicalWidth == 0.0 ? [.height(435)] : [.height(370)])
        .presentationDragIndicator(.visible)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveChanges() {
        guard !newName.isEmpty else {
            alertMessage = "Name cannot be empty."
            showAlert = true
            return
        }
        
        guard let size = Double(newSize), size > 0 else {
            alertMessage = "Size must be a valid positive number."
            showAlert = true
            return
        }
        
        marker.imageName = newName
        marker.physicalWidth = CGFloat(size)
        
        let fileMarkerDataURL = room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("Marker Data.json")
        
        marker.saveMarkerData(to: fileMarkerDataURL,
                              old: oldName,
                              new: marker.imageName,
                              size: marker.physicalWidth
        )
        
        dismiss()
    }
}
