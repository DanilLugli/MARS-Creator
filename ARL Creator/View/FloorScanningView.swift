import SwiftUI
import ARKit
import RoomPlan

struct FloorScanningView: View {
    @State var namedUrl: NamedURL
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    @State var isScanningFloor = false
    
    @State var captureView: FloorCaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss

    init(namedUrl: NamedURL) {
        self._namedUrl = State(initialValue: namedUrl)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isScanningFloor, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar) 
                }
                
                else {
                    Text("Press Start to begin scanning of \(namedUrl.name)")
                        .foregroundColor(.gray)
                        .bold()
                }
                
                VStack {
                    HStack {
                        if isScanningFloor {
                            
                            //SAVE ALTITUDE
                            
                            ScanningCardView(
                                messagesFromWorldMap: messagesFromWorldMap,
                                newFeatures: namedUrl is Room ? worldMapNewFeatures : nil,
                                
                                onSave: {
                                    isScanningFloor = true
                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                    captureView?.stopCapture()
                                },
                                onRestart: {
                                    captureView?.redoCapture()
                                },
                                saveMap: {
                                    print("saveMap")
                                }
                            )
                            .ignoresSafeArea()
                            .padding()
                            .zIndex(1)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    if !isScanningFloor {
                        Button(action: {
                            isScanningFloor = true
                            captureView = FloorCaptureViewContainer(namedUrl: namedUrl)
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
                .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                    if let message = notification.object as? String {
                        self.message = message
                    }
                }
            }
            
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(namedUrl.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct FloorScanningView_Previews: PreviewProvider {
    static var previews: some View {
        FloorScanningView(namedUrl: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _sceneConfiguration: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
