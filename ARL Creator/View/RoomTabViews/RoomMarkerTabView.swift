import SwiftUI
import ARKit
import AlertToast

struct RoomMarkerTabView: View {
    
    @ObservedObject var room: Room
    
    @State private var searchText: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    
    @StateObject private var worldMapLoader: ARWorldMapLoader
    
    @State private var arViewContainer: FindMarkerPositionARSession
    
    @State private var showDeleteRMToast: Bool = false
    @State private var showUpdateRMToast: Bool = false
    
    init(room: Room) {
            self.room = room
            _worldMapLoader = StateObject(wrappedValue: ARWorldMapLoader(roomURL: room.roomURL, roomName: room.name))
             arViewContainer = FindMarkerPositionARSession(worldMapURL: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MyARWorldMap.worldmap"), room: room)
        }
    
//    let mapFileWithExtension = roomURL.appendingPathComponent("Maps").appendingPathComponent("\(room.name).map")
//    let mapFileWithoutExtension = roomURL.appendingPathComponent("Maps").appendingPathComponent(room.name)
//    
//    if FileManager.default.fileExists(atPath: mapFileWithExtension.path) {
//        guard let mapData = try? Data(contentsOf: mapFileWithExtension),
//              let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
//        else {
//            print("Failed to load ARWorldMap from \(mapFileWithExtension.path)")
//            continue
//        }
//       
//        room.arWorldMap = worldMap
//        
//    } else if FileManager.default.fileExists(atPath: mapFileWithoutExtension.path) {
//        guard let mapData = try? Data(contentsOf: mapFileWithoutExtension),
//              let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
//        else {
//            print("Failed to load ARWorldMap from \(mapFileWithoutExtension.path)")
//            continue
//        }
//        room.arWorldMap = worldMap
//    }
//    else {
//        print("File ARWorldMap for \(room.name) not found.")
//    }
    
    
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
//        .toast(isPresenting: $showDeleteRMToast, duration: 5.0) {
//            AlertToast(
//                displayMode: .hud,
//                type: .regular,
//                title: "Deleted",
//                subTitle: "Reference Marker Deleted"
//            )
//        }
//        .toast(isPresenting: $showUpdateRMToast) {
//            AlertToast(
//                type: .regular,
//                title: "Updated",
//                subTitle: "Reference Marker Updated"
//            )
//        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
        .sheet(item: $selectedMarker) { marker in
            MarkerDetailView(
                marker: marker,
                room: room,
                worldMapURL: room.roomURL.appendingPathComponent("Maps").appendingPathComponent("\(room.name).map"),
                showDeleteRMToast: $showDeleteRMToast,
                showUpdateRMToast: $showUpdateRMToast
            )
        }
        
    }
}

struct MarkerDetailView: View {
    @ObservedObject var marker: ReferenceMarker
    @ObservedObject var room: Room
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newName: String
    @State private var newSize: String
    private var oldName: String
    
    @State private var alertMessage = ""
    
    @State private var isShowingARSession = false
    @State private var showAlert = false
    
    @Binding var showDeleteRMToast: Bool
    @Binding var showUpdateRMToast: Bool
    
    let worldMapURL: URL?
    
    init(marker: ReferenceMarker, room: Room, worldMapURL: URL?,  showDeleteRMToast: Binding<Bool>, showUpdateRMToast: Binding<Bool>) {
        self.room = room
        self.marker = marker
        self.oldName = marker.imageName
        self.worldMapURL = worldMapURL
        self._showDeleteRMToast = showDeleteRMToast
        self._showUpdateRMToast = showUpdateRMToast
        
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
//                    HStack {
//                        Image(systemName: "characters.lowercase")
//                            .font(.headline)
//                            .bold()
//                            .foregroundColor(.customBackground)
//                        
//                        Text("Name:")
//                            .font(.headline)
//                            .bold()
//                            .foregroundColor(.customBackground)
//                        
//                    }
//                    
//                    TextField("Enter marker name", text: $newName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .foregroundColor(self.oldName == "room_photo" ? .red : .customBackground)
//                        .bold()
//                        .padding(.bottom)
                    
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
                        DispatchQueue.main.async {
                            showDeleteRMToast = true
                        }
                    }) {
                        Text("Delete")
                            .font(.headline)
                            .bold()
                            .padding()
//                            .background()
                            .foregroundColor(Color.red)
                            .cornerRadius(30)
                    }
                    
                    Button(action: {
                        saveChanges()
                        DispatchQueue.main.async {
                            showUpdateRMToast = true
                        }
                    }){
                        Text("Save")
                            .font(.headline)
                            .bold()
                            .padding()
//                            .background()
                            .foregroundColor(Color.green)
                            .cornerRadius(30)
                    }
                    
                   
                    
//                    if let worldMapURL = worldMapURL {
//                        Button(action: {
//                            print("✅ Button pressed!") // Debug: Controlla se il bottone viene premuto
//                            isShowingARSession = true
//                        }) {
//                            Text("Calculate Position")
//                                .font(.headline)
//                                .bold()
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(30)
//                        }
//                        .fullScreenCover(isPresented: $isShowingARSession) {
//                           
//                            FindMarkerPositionARSession(worldMapURL: worldMapURL, room: room)
//                                .edgesIgnoringSafeArea(.all)
//                        }
//                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .presentationDetents(marker.physicalWidth == 0.0 ? [.height(250)] : [.height(250)])
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
        
        guard newName != "room_photo" else {
            alertMessage = "Name cannot be 'room_photo'."
            showAlert = true
            return
        }

        guard let size = Double(newSize), size > 0.0 else {
            alertMessage = "Size must be a valid positive number."
            showAlert = true
            return
        }
        

        let oldNameWithoutExtension = URL(fileURLWithPath: oldName).deletingPathExtension().lastPathComponent
        let newNameWithoutExtension = URL(fileURLWithPath: newName).deletingPathExtension().lastPathComponent

        
        let referenceMarkerURL = room.roomURL.appendingPathComponent("ReferenceMarker")
        let fileMarkerDataURL = referenceMarkerURL.appendingPathComponent("Marker Data.json")
        
        let directoryURL = referenceMarkerURL
        let fileNameWithoutExtension = oldNameWithoutExtension
        var exteImage = ""
        if let fileURL = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .first(where: { $0.deletingPathExtension().lastPathComponent == fileNameWithoutExtension }) {
            
            print("File trovato: \(fileURL.lastPathComponent)")
            print("Estensione: \(fileURL.pathExtension)")
            exteImage = fileURL.pathExtension
        } else {
            print("File non trovato")
        }

        
        if let index = room.referenceMarkers.firstIndex(where: { $0.imageName == oldNameWithoutExtension }) {
            room.referenceMarkers.remove(at: index)
        }

        let updatedMarker = ReferenceMarker(
                  _imagePath: referenceMarkerURL.appendingPathComponent("\(newNameWithoutExtension).\(exteImage)"),
                  _imageName: newNameWithoutExtension,
                  _coordinates: simd_float3(0, 0, 0),
                  _rmUML: referenceMarkerURL.appendingPathComponent("newNameWithoutExtension.jpg"),
                  _physicalWidth: CGFloat(size)
              )
        

        room.referenceMarkers.append(updatedMarker)

        marker.saveMarkerData(
                   to: fileMarkerDataURL,
                   old: oldNameWithoutExtension,
                   new: newNameWithoutExtension,
                   size: CGFloat(size),
                   newCoordinates: updatedMarker.coordinates
               )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
    
    private func deleteMarker(markerName: String) {
        let referenceMarkerURL = room.roomURL.appendingPathComponent("ReferenceMarker")

        let oldNameWithoutExtension = URL(fileURLWithPath: oldName).deletingPathExtension().lastPathComponent
        let newNameWithoutExtension = URL(fileURLWithPath: newName).deletingPathExtension().lastPathComponent

        let fileMarkerDataURL = referenceMarkerURL.appendingPathComponent("Marker Data.json")
        
        let directoryURL = referenceMarkerURL
        let fileNameWithoutExtension = oldNameWithoutExtension
        var exteImage = ""
        if let fileURL = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .first(where: { $0.deletingPathExtension().lastPathComponent == fileNameWithoutExtension }) {
            
            print("File trovato: \(fileURL.lastPathComponent)")
            print("Estensione: \(fileURL.pathExtension)")
            exteImage = fileURL.pathExtension
        } else {
            print("File non trovato")
        }

        
        let markerFileURL = referenceMarkerURL.appendingPathComponent("\(markerName).\(exteImage)")

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
        
        marker.deleteMarkerData(from: referenceMarkerURL.appendingPathComponent("Marker Data.json"), markerName: markerName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dismiss()
        }
    }
}


class ARWorldMapLoader: ObservableObject {
    @Published var worldMapURL: URL?
    
    init(roomURL: URL, roomName: String) {
        loadWorldMap(roomURL: roomURL, roomName: roomName)
    }
    
    private func loadWorldMap(roomURL: URL, roomName: String) {
        let mapFileWithExtension = roomURL.appendingPathComponent("Maps").appendingPathComponent("\(roomName).map")
        let mapFileWithoutExtension = roomURL.appendingPathComponent("Maps").appendingPathComponent(roomName)
        
        if FileManager.default.fileExists(atPath: mapFileWithExtension.path) {
            
            self.worldMapURL = mapFileWithExtension
        } else if FileManager.default.fileExists(atPath: mapFileWithoutExtension.path) {
           
            self.worldMapURL = mapFileWithoutExtension
        } else {
            print("⚠️ No ARWorldMap \(roomName).")
        }
    }
}


