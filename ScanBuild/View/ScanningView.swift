import SwiftUI
import ARKit
import RoomPlan

struct ScanningView: View {
    @State var namedUrl: NamedURL
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State var isScanningRoom = true
    
    @State var captureView: CaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    init(namedUrl: NamedURL) {
        self._namedUrl = State(initialValue: namedUrl)
        self._captureView = State(initialValue: CaptureViewContainer(namedUrl: namedUrl))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Text("Loading...")
                        .onAppear {
                            captureView = CaptureViewContainer(namedUrl: namedUrl)
                        }
                }
                
                VStack {
                    HStack {
                        ScanningCardView(worldMapCounter: worldMapCounter, messagesFromWorldMap: messagesFromWorldMap, newFeatures: worldMapNewFeatures, onSave: {
                            isScanningRoom = false
                            let finalMapName = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                            captureView?.stopCapture(pauseARSession: false)
                        })
                        .padding()
                        
                        Spacer()
                    }.padding(.top, -300)
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
                    if let counter = notification.object as? Int {
                        self.worldMapCounter = counter
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
                    if let worldMap = notification.object as? ARWorldMap {
                        self.messagesFromWorldMap = """
                        mapDimension in m2: \(worldMap.extent.x * worldMap.extent.z)\n
                        anchors: \(worldMap.anchors.count)\n
                        features: \(worldMap.rawFeaturePoints.identifiers.count)
                        """
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .worlMapNewFeatures)) { notification in
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
                captureView?.stopCapture(pauseARSession: false)
            }
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView(namedUrl: Floor(name: "Sample Floor", lastUpdate: Date(), planimetry: Image(""), associationMatrix: [:], rooms: [], sceneObjects: [], scene: nil, sceneConfiguration: nil, floorURL: URL(fileURLWithPath: "")))
    }
}
