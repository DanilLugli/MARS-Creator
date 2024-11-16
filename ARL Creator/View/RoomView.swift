import SwiftUI
import Foundation
import Combine

struct RoomView: View {
    
    @EnvironmentObject var buildingModel: BuildingModel
    @Environment(\.dismiss) private var dismiss // Environment dismiss for navigation back
    
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @ObservedObject var building: Building
    
    @State private var newRoomName: String = ""
    @State private var selectedMarker: ReferenceMarker? = nil
    @State private var selectedConnection: TransitionZone? = nil
    @State private var selectedTransitionZone: TransitionZone? = nil
    @State private var selectedTab: Int = 0
    @State private var selectedFileURL: URL?
    @State private var selectedImageURL: URL?
    
    @State private var isRenameSheetPresented = false
    @State private var isNavigationScanRoomActive = false
    @State private var isConnectionAdjacentFloor = false
    @State private var isRoomPlanimetryUploadPicker = false
    @State private var isConnectionSameFloor = false
    @State private var isErrorAlertPresented = false
    @State private var isOptionsSheetPresented = false
    @State private var isUpdateOpenView = false
    @State private var isCreateRoomPosition = false
    @State private var isCreateManualRoomPosition = false
    @State private var isReferenceMarkerUploadPicker = false
    @State private var isColorPickerPopoverPresented = false
    
    @State private var showUpdateOptionsAlert = false
    @State private var showUpdateAlert = false
    @State private var showDeleteConfirmation = false
    
    @State private var selectedColor = Color(
        .sRGB,
        red: 0.98,
        green: 0.9,
        blue: 0.2)
    
    @State private var errorMessage: String = ""
    @State private var alertMessage = ""
    @State private var searchText: String = ""
    
    @State var mapRoomPositionView = SCNViewMapContainer()
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    HStack(spacing: 4) {
                        Text(building.name)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                        Text(floor.name)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                        Text(room.name)
                    }
                    .font(.system(size: 14))
                    .fontWeight(.heavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    
                    TabView(selection: $selectedTab) {
                        RoomPlanimetryView(room: room)
                            .tabItem {
                                Label("Room Planimetry", systemImage: "map.fill")
                            }
                            .tag(0)
                        
                        RoomPositionTabView(room: room, floor: floor)
                            .tabItem {
                                Label("Room Position", systemImage: "sum")
                            }
                            .tag(1)
                        
                        MarkerView(room: room)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.customBackground)
                            .tabItem {
                                Label("Marker", systemImage: "photo")
                            }
                            .tag(2)
                        
                        TransitionZoneTabView(room: room)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.customBackground)
                            .tabItem {
                                Label("Transition Zones", systemImage: "mappin.and.ellipse")
                            }
                            .tag(4)
                        
                        ConnectionsTabView(room: room, floor: floor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.customBackground)
                            .tabItem {
                                Label("Connections", systemImage: "arrow.left.arrow.right")
                            }
                            .tag(3)
                    }
                }
                .background(Color.customBackground)
                .foregroundColor(.white)
            }
            .navigationDestination(isPresented: $isNavigationScanRoomActive) {
                ScanningView(namedUrl: room)
            }
            .navigationTitle("Room")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            isRenameSheetPresented = true
                        }) {
                            Label("Rename Room", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            isOptionsSheetPresented = true
                        }) {
                            Label("Create Planimetry", systemImage: "plus")
                        }
                        .disabled(FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                        
                        Button(action: {
                            alertMessage = "If you proceed with the update, the current floor plan will be deleted.\nThis action is irreversible, are you sure you want to continue?"
                            showUpdateAlert = true
                        }) {
                            Label("Update Planimetry", systemImage: "arrow.clockwise")
                        }
                        .disabled(!FileManager.default.fileExists(atPath: room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz").path))
                        
                        Divider()
                        
                        Button(action: {
                            isColorPickerPopoverPresented = true
                        }) {
                            Label("Change Room Color", systemImage: "paintpalette")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                Text("Delete Room")
                                    .foregroundColor(.red)
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue, .blue)
                    }
                }
            }
            .confirmationDialog("Are you sure to delete Room?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Yes", role: .destructive) {
                    floor.deleteRoom(room: room)
                    dismiss() // Navigate back after deletion
                    print("Room deleted and navigating back")
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .alert(isPresented: $isErrorAlertPresented) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}


struct RoomView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        return RoomView(room: room, floor: floor, building: building).environmentObject(buildingModel)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
