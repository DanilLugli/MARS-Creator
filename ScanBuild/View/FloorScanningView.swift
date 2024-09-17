import SwiftUI
import ARKit
import RoomPlan

struct FloorScanningView: View {
    @State var namedUrl: NamedURL
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    @State var isScanningRoom = false
    
    @State var captureView: FloorCaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    @Environment(\.presentationMode) var presentationMode

    init(namedUrl: NamedURL) {
        self._namedUrl = State(initialValue: namedUrl)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isScanningRoom, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Text("Press Start to begin scanning of \(namedUrl.name)")
                        .foregroundColor(.gray).bold()
                        .onAppear {
                            // Placeholder
                        }
                }
                
                VStack {
                    HStack {
                        if isScanningRoom {
                            ScanningCardView(
                                messagesFromWorldMap: messagesFromWorldMap,
                                newFeatures: namedUrl is Room ? worldMapNewFeatures : nil,
                                onSave: {
                                    isScanningRoom = false
                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                    captureView?.stopCapture()
                                }
                            )
                            .padding()
                            .zIndex(1)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    if !isScanningRoom {
                        Button(action: {
                            isScanningRoom = true
                            captureView = FloorCaptureViewContainer(namedUrl: namedUrl)
                        }) {
                            Text("Start")
                                .font(.largeTitle).bold()
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
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
                    Text(namedUrl.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .onDisappear {
                //captureView?.stopCapture(pauseARSession: false, saveData: false)
            }
        }
    }
}

struct FloorScanningView_Previews: PreviewProvider {
    static var previews: some View {
        FloorScanningView(namedUrl: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _sceneConfiguration: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
