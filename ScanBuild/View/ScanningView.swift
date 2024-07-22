import SwiftUI
import ARKit
import RoomPlan

struct ScanningView: View {
    
    @Binding var room: Room?
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worlMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State var isScanningRoom = true
    
    var roomcaptureView = RoomCaptureViewContainer()
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                roomcaptureView
                    .edgesIgnoringSafeArea(.all)
                
                VStack{
                    HStack {
                        ScanningCardView(worldMapCounter: worldMapCounter, messagesFromWorldMap: messagesFromWorldMap, newFeatures: worlMapNewFeatures, onSave: {
                            isScanningRoom = false
                            let finalMapName = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                            roomcaptureView.stopCapture(pauseARSession: false, mapName: finalMapName)
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
                        self.worlMapNewFeatures = newFeatures
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
                    Text(room?.name ?? "SCANNING ROOM")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
        }
    }

    
    struct ScanningView_Previews: PreviewProvider {
        static var previews: some View {
            ScanningView(room: .constant(Room(name: "Preview Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath: ""))))
        }
    }
}
