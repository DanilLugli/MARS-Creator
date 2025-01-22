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
    
    @State var showCreateRoomPlanimetryToast = false
    
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
                if isScanningRoom, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar) 
                } else {
                    Text("Press Start to begin scanning of \(room.name)")
                        .foregroundColor(.gray)
                        .bold()
                }
                
                VStack {
                    HStack {
                        if isScanningRoom {
                            if showScanningRoomCard == true{
                                VStack{
                                    Text(String(format: "Features Point: %d", worldMapNewFeatures))
                                        .font(.system(size: 18, weight: .bold, design: .default))
                                        .foregroundColor(.black)
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                        .padding()
                                    
//                                    Spacer()
//                                    Button(action: {
//                                        isScanningRoom = true
//                                        
//                                        captureView?.stopCapture()
//                                        showScanningRoomCard = false
//                                        let finalMapName = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                    }) {
//                                        Text("Done")
//                                            .font(.system(size: 16, weight: .bold, design: .default))
//                                            .bold()
//                                            .padding()
//                                            .background(Color.green)
//                                            .foregroundColor(.white)
//                                            .cornerRadius(30)
//                                            .frame(maxWidth: 150)
//                                    }.padding()
                                }

                                
//                                ScanningCardView(
//                                    messagesFromWorldMap: messagesFromWorldMap,
//                                    newFeatures: room is Room ? worldMapNewFeatures : nil,
//                                    onSave: {
//                                        isScanningRoom = true
//                                        //let finalMapName = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                        
//                                        captureView?.stopCapture()
//                                        showScanningRoomCard = false
//                                    },
//                                    onRestart: {
//                                        captureView?.redoCapture()
//                                    },
//                                    saveMap: {
//                                        print("saveMap")
//                                    }
//                                )
//                                .padding()
//                                .zIndex(1)
                            }

//                            else{
                                VStack{
                                    Spacer()
                                    HStack{
                                
                                        Button(action: {
                                            if showScanningRoomCard{
                                                isScanningRoom = true
                                                
                                                captureView?.stopCapture()
                                                showScanningRoomCard = false
                                                let finalMapName = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
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
                                                .frame(maxWidth: 150)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                        
                                }
//                            }
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
                                .font(.title)
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
            .background(Color.customBackground.ignoresSafeArea())
            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String {
                    self.message = message
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
