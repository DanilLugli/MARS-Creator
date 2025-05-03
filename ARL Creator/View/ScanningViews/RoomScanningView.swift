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
    @State var showProgressView = false
    
    @State private var scannedDistance: CGFloat = 0.0
    @State private var featuresPoint: Int = 0
    @State private var detectedObjects: Int = 0
    
    @State var captureView: RoomCaptureViewContainer?
    @StateObject var sessionDelegate: RoomCaptureViewContainer.SessionDelegate
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    @State private var viewError: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    init(room: Room) {
        self._room = State(initialValue: room)
        _sessionDelegate = StateObject(wrappedValue: RoomCaptureViewContainer.SessionDelegate(room: room))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.customBackground.ignoresSafeArea()
                if isScanningRoom, let captureView = captureView {
                    ZStack(alignment: .top) {
                        captureView
                            .edgesIgnoringSafeArea(.all)
                            .toolbarBackground(.hidden, for: .navigationBar)
                        
                        if showProgressView{
                            RoomScanProgressView(scannedDistance: sessionDelegate.userDistance, detectedObjects: sessionDelegate.detectedObjects, featuresPoint: worldMapNewFeatures)
                                .padding(.top, 20)
                        }

                    }
                }
                else {
                    
                    VStack{
                        Text("How to Scan a Room")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    VStack{
                        Text("""
                        • Scan one room at a time, focusing on objects within the space that help capture feature points, such as paintings, colorful objects, and furniture.
                        • You can monitor the number of detected feature points during the scanning process.
                        • Once the scan is complete, press **Done**.
                        """)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        
                        Text("PRESS START TO SCAN \(room.name)")
                            .foregroundColor(.gray)
                            .bold()
                    }
                    
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
                                        .cornerRadius(20)
                                        .shadow(radius: 5)
                                        .padding(.top, 60)
                                        .frame(maxWidth: .infinity)
                                    
                                }.padding(.top,28)
                            }

                            VStack{
                                
                                VStack{
                                    
                                    if let scanningError = scanningError, !scanningError.isEmpty, viewError == true {

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
                                                showProgressView = true
                                                viewError = false
                                            }) {
                                                Text("Restart Scan")
                                                    .font(.system(size: 16, weight: .bold, design: .default))
                                                    .bold()
                                                    .padding()
                                                    .frame(maxWidth: .infinity)
//                                                    .background(Color.red)
                                                    .foregroundColor(.red)
                                                    .cornerRadius(30)
                                            }
                                            .padding(.horizontal, 20)
                                        
                                    }
                                        
                                    
                                    Spacer()
                                    
                                    HStack{
                                        Spacer()
                                        if !showScanningRoomCard{
                                            Button(action: {
                                                showCreateRoomPlanimetryToast = true
                                                showProgressView = false
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                    dismiss()
                                                }
                                            }) {
                                                Text("Finish")
                                                    .font(.system(size: 18, weight: .bold, design: .default))
                                                    .bold()
                                                    .padding()
                                                    .foregroundColor(Color.green)
                                                    .cornerRadius(30)
                                            }.padding(.trailing, 20)
                                            
                                        }
                                    }

                                    HStack{
                                        Spacer()
                                        if showScanningRoomCard{
                                            
                                            Button(action: {
                                                isScanningRoom = true
                                                showProgressView = false
                                                captureView?.stopCapture()
                                                showScanningRoomCard = false
                                                _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                            }) {
                                                Text("Done")
                                                    .font(.system(size: 18, weight: .bold, design: .default))
                                                    .bold()
                                                    .padding()
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(30)
                                                
                                            }.padding(.trailing, 20)
                                        }
                                    }


                                    
                                }
                                .frame(maxWidth: .infinity)
                               
                            }//.border(Color.red, width: 2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                           
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    if !isScanningRoom {
                        Button(action: {
                            isScanningRoom = true
                            captureView = RoomCaptureViewContainer(room: room, sessionDelegate: sessionDelegate)
                            showProgressView = true
                            
                        }) {
                            Text("Start")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .bold()
                                .padding()
//                                .background(Color.blue)
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
                }.onReceive(sessionDelegate.$userDistance) { newValue in
                    print("DEBUG: userDistance aggiornato in RoomScanningView -> \(newValue) metri")
                }
                .onReceive(sessionDelegate.$detectedObjects) { newValue in
                    print("DEBUG: detectedObjects aggiornato in RoomScanningView -> \(newValue)")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    self.message = message
                }
            }.onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    if message == "World tracking failure" {
                        viewError = true
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
