import SwiftUI
import AlertToast

struct RoomMarkerTabView: View {
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
                HStack{
                    HStack{
                        Text("Add Marker with")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                        
                        Text("icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                }
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
    
    
    @State private var showDeleteRMToast: Bool = false
    @State private var showUpdateRMToast: Bool = false

    
    private var oldName: String
    
    init(marker: ReferenceMarker, room: Room) {
        self.room = room
        self.marker = marker
        self.oldName = marker.imageName
        
        _newName = State(initialValue: marker.imageName)
        _newSize = State(initialValue: "\(marker.physicalWidth)")
    }
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)
                    
                    Text("Marker Details")
                        .font(.title)
                        .foregroundColor(.customBackground)
                        .bold()
                }.padding(.bottom)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "characters.lowercase")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.customBackground)
                        
                        Text("Name:")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.customBackground)
                        
                    }
                    
                    TextField("Enter marker name", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.customBackground)
                        .bold()
                        .padding(.bottom)
                    
                    HStack{
                        Image(systemName: "ruler")
                            .foregroundColor(.customBackground)
                        
                        Text("Width (cm):")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.customBackground)
                    }
                    
                    TextField("Enter marker size", text: $newSize)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .foregroundColor(marker.physicalWidth == 0.0 ? .red: .customBackground)
                        .bold()
                        .padding(.bottom)
                }
                
                HStack{
                    Button(action: {
                        deleteMarker(markerName: marker.imageName)
                        showDeleteRMToast = true
                    }) {
                        Text("Delete")
                            .font(.headline)
                            .bold()
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    
                    Button(action: {
                        saveChanges()
                        showUpdateRMToast = true
                    }){
                        Text("Save")
                            .font(.headline)
                            .bold()
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .presentationDetents(marker.physicalWidth == 0.0 ? [.height(355)] : [.height(355)])
        .presentationDragIndicator(.visible)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Input"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .toast(isPresenting: $showDeleteRMToast){
            AlertToast(displayMode: .banner(.slide), type: .regular, title: "Reference Marker Deleted")
        }
        .toast(isPresenting: $showUpdateRMToast){
            AlertToast(displayMode: .banner(.slide), type: .regular, title: "Reference Marker Updated")
        }
    }
    
    private func saveChanges() {
        guard !newName.isEmpty else {
            alertMessage = "Name cannot be empty."
            showAlert = true
            return
        }

        guard let size = Double(newSize), size > 0.0 else {
            alertMessage = "Size must be a valid positive number."
            showAlert = true
            return
        }
        
        marker.imageName = newName
        marker.physicalWidth = CGFloat(size)
        
        let referenceMarkerURL = room.roomURL.appendingPathComponent("ReferenceMarker")
        let fileMarkerDataURL = referenceMarkerURL.appendingPathComponent("Marker Data.json")
        let oldFileURL = referenceMarkerURL.appendingPathComponent("\(oldName)")
        let newFileURL = referenceMarkerURL.appendingPathComponent("\(newName).jpg")
        
        do {
            if FileManager.default.fileExists(atPath: oldFileURL.path) {
                try FileManager.default.moveItem(at: oldFileURL, to: newFileURL)
            }
        }
        catch {
            alertMessage = "Failed to rename the image file: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        marker.saveMarkerData(to: fileMarkerDataURL,
                              old: oldName,
                              new: newName,
                              size: marker.physicalWidth
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
    
    private func deleteMarker(markerName: String) {
        let referenceMarkerURL = room.roomURL.appendingPathComponent("ReferenceMarker")
        let markerFileURL = referenceMarkerURL.appendingPathComponent("\(markerName).jpg")

        if let index = room.referenceMarkers.firstIndex(where: { $0.imageName == markerName }) {
            room.referenceMarkers.remove(at: index)
        }
        else {
            alertMessage = "Marker not found in the room."
            showAlert = true
            return
        }

        do {
            if FileManager.default.fileExists(atPath: markerFileURL.path) {
                try FileManager.default.removeItem(at: markerFileURL)
                print("Marker file deleted successfully.")
            }
        }
        catch {
            alertMessage = "Failed to delete the marker file: \(error.localizedDescription)"
            showAlert = true
        }
        
        marker.deleteMarkerData(from: referenceMarkerURL.appendingPathComponent("Marker Data.json"), markerName: marker.imageName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}
