import SwiftUI
import Foundation
import UIKit
import UniformTypeIdentifiers

struct RoomView: View {
    
    @ObservedObject var floor: Floor
    var building: Building
    @State private var searchText: String = ""
    @State private var isRenameSheetPresented = false
    @State private var newBuildingName: String = ""
    @State private var selectedTab: Int = 0
    @State private var animateRooms: Bool = false
    @State private var newRoom: Room? = nil
    @State private var isNavigationActive = false
    @State private var isDocumentPickerPresented = false
    @State private var selectedFileURL: URL?
    @State private var showFloorMap: Bool = false
    var mapView = SCNViewContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("\(building.name) > \(floor.name)")
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                
                
                TabView(selection: $selectedTab) {
                    
                    VStack {
                        
                        Toggle(isOn: $showFloorMap) {
                            Text("Show Local Map")
                                .font(.system(size: 20)).bold()
                        }.toggleStyle(SwitchToggleStyle()).padding()
                        
                        if floor.planimetry == nil {
                            Text("Add Planimetry with + icon")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        } else {
                            VStack {
                                mapView
                                    .border(Color.white).cornerRadius(10).padding().shadow(color: Color.gray, radius: 3)
                            }
                            .onAppear {
                                mapView.loadgeneralMap(borders: true, usdzURL: floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz"))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground)
                    .tabItem {
                        Label("Planimetry", systemImage: "map.fill")
                    }
                    .tag(0)
                    
                    
                    
                    VStack {
                        
                        TextField("Search", text: $searchText)
                            .padding(7)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .padding()
                        
                        if floor.rooms.isEmpty {
                            VStack {
                                Text("Add Room to \(floor.name) with + icon")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                    .padding()
                            }
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 50) {
                                    ForEach(floor.rooms, id: \.id) { room in
                                        NavigationLink(destination: MarkerView(room: room, building: building, floor: floor)) {
                                            DefaultCardView(name: room.name, date: room.lastUpdate).padding()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.customBackground)
                    .tabItem {
                        Label("Rooms", systemImage: "list.dash")
                    }
                    .tag(1)

                }
            }
            .background(Color.customBackground)
            .foregroundColor(.white)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("FLOOR")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if selectedTab == 0 {
                        Menu {
                            Button(action: {
                                // Azione per il pulsante "Rename"
                                isDocumentPickerPresented = true
                            }) {
                                Label("Upload File", systemImage: "pencil")
                            }
                            
                            // Aggiungiamo il pulsante che naviga verso ScanningView
                            Button(action: {
                                let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                                self.newRoom = newRoom
                                self.isNavigationActive = true
                            }) {
                                Label("Add Room", systemImage: "plus.circle.fill")
                            }
                            
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue, .blue)
                        }

                        NavigationLink(destination: ScanningView(namedUrl: floor), isActive: $isNavigationActive) {
                            EmptyView()
                        
                        }
                        
//                        NavigationLink(destination: ScanningView(namedUrl: floor), isActive: $isNavigationActive) {
//                            Image(systemName: "plus.circle.fill")
//                                .font(.system(size: 26))
//                                .foregroundStyle(.white, .blue, .blue)
//                                .onTapGesture {
//                                    let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
//                                    self.newRoom = newRoom
//                                    self.isNavigationActive = true
//                                }
//                        }
                    } else if selectedTab == 1 {
                        NavigationLink(destination: AddRoomView(floor: floor), isActive: $isNavigationActive) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white, .blue, .blue)
                                .onTapGesture {
                                    let newRoom = Room(name: "New Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))
                                    self.newRoom = newRoom
                                    self.isNavigationActive = true
                                }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isRenameSheetPresented) {
            VStack {
                Text("Rename Building")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .foregroundColor(.white)
                TextField("New Building Name", text: $newBuildingName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                Spacer()
                Button(action: {
                    if !newBuildingName.isEmpty {
                        // Salva il nuovo nome dell'edificio
                    }
                }) {
                    Text("SAVE")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding()
            .background(Color.customBackground.ignoresSafeArea())
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            DocumentPicker { url in
                selectedFileURL = url
                // Gestisci il file selezionato qui
                print("Selected file URL: \(url)")
            }
        }
    }
    
    var filteredRooms: [Room] {
        if searchText.isEmpty {
            return floor.rooms
        } else {
            return floor.rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.content, UTType.item], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let pickedURL = urls.first else { return }
            onPick(pickedURL)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        
        return RoomView(floor: floor, building: building)
    }
}
