import SwiftUI
import AlertToast
import ARKit
import RoomPlan

struct RoomScanningView: View {
    @State var room: Room
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    
    @State var isScanningRoom = false
    @State var showScanningRoomCard = true
    
    @State private var scanningError: String? = ""
    
    @State var showCreateRoomPlanimetryToast = false
    @State var showRestartButton = false
    
    @State var captureView: RoomCaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    init(room: Room) {
        self._room = State(initialValue: room)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBackground.ignoresSafeArea()
                if isScanningRoom, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
                else {
                    Text("Press Start to begin scanning of \(room.name)")
                        .foregroundColor(.gray)
                        .bold()
                }
                
                VStack {
                    VStack {
                        if isScanningRoom {
                            if showScanningRoomCard {
                                VStack {
                                    Text(String(format: "Features Point: %d", worldMapNewFeatures))
                                        .font(.system(size: 18, weight: .bold, design: .default))
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                        .padding(.top, 60)
                                        .frame(maxWidth: .infinity)
                                    
                                }
                            }

                            VStack{
                                Spacer()
                                HStack{
                                    
                                    if let scanningError = scanningError, !scanningError.isEmpty {

                                            Text("An error occurred:")
                                                .font(.headline)
                                                .foregroundColor(.red)
                                                .padding(.bottom, 5)
                                            
                                            Text(scanningError)
                                                .font(.subheadline)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 20)
                                        
                                            Button(action: {
                                                captureView?.restartCapture()
                                            }) {
                                                Text("Restart Scan")
                                                    .font(.system(size: 16, weight: .bold, design: .default))
                                                    .bold()
                                                    .padding()
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.red)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(30)
                                            }
                                            .padding(.horizontal, 20)
                                        
                                    }
                                        
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if showScanningRoomCard{
                                            isScanningRoom = true
                                            
                                            captureView?.stopCapture()
                                            showScanningRoomCard = false
                                            _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                        }
                                        else{
                                            showCreateRoomPlanimetryToast = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                dismiss()
                                            }
                                        }
                                    }) {
                                        Text("Done")
                                            .font(.system(size: 16, weight: .bold, design: .default))
                                            .bold()
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                    }.padding(.trailing, 20)
                                    
                                }
                                .frame(maxWidth: .infinity)
                               
                            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                           
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    if !isScanningRoom {
                        Button(action: {
                            isScanningRoom = true
                            captureView = RoomCaptureViewContainer(room: room)
                        }) {
                            Text("Start")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .bold()
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        .padding()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
                    if let counter = notification.object as? Int {
                        self.worldMapCounter = counter
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
                    if let worldMap = notification.object as? ARWorldMap {
                        self.messagesFromWorldMap = """
                        features: \(worldMap.rawFeaturePoints.identifiers.count)
                        """
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapNewFeatures)) { notification in
                    if let newFeatures = notification.object as? Int {
                        self.worldMapNewFeatures = newFeatures
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    self.message = message
                }
            }.onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    if message == "World tracking failure" {
                        self.scanningError = message
                    }
                    
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(room.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .toast(isPresenting: $showCreateRoomPlanimetryToast) {
                AlertToast(type: .complete(Color.green), title: "Room Planimetry created")
            }
        }
    }
}

struct RoomScanningView_Previews: PreviewProvider {
    static var previews: some View {
        let buildingModel = BuildingModel.getInstance()
        let building = buildingModel.initTryData()
        let floor = building.floors.first!
        let room = floor.rooms.first!
        return RoomScanningView(room: room).environmentObject(buildingModel)
        //        FloorScanningView(floor: Room(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
