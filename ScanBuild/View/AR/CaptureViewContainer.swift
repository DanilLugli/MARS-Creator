import SwiftUI
import RoomPlan
import ARKit

struct CaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView
    var arSession = ARSession()
    
    var sessionDelegate: SessionDelegate
    
    private let configuration: RoomCaptureSession.Configuration
    
    init(namedUrl: NamedURL) {
        print("init captureView")
        sessionDelegate = SessionDelegate(namedUrl: namedUrl)
        configuration = RoomCaptureSession.Configuration()
        
        if #available(iOS 17.0, *) {
            roomCaptureView = RoomCaptureView(frame: .zero, arSession: arSession)
        } else {
            roomCaptureView = RoomCaptureView(frame: .zero)
        }
        
        roomCaptureView.captureSession.delegate = sessionDelegate
        roomCaptureView.delegate = sessionDelegate
        roomCaptureView.captureSession.arSession.delegate = sessionDelegate
        sessionDelegate.setCaptureView(self)
    }
    
    func makeUIView(context: Context) -> RoomCaptureView {
        roomCaptureView.captureSession.run(configuration: configuration)
        return roomCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func stopCapture(pauseARSession: Bool) {
        SessionDelegate.save = !pauseARSession
        sessionDelegate.currentMapName = sessionDelegate.namedUrl.name
        
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: pauseARSession)
        } else {
            roomCaptureView.captureSession.stop()
        }
        
        if !pauseARSession {
            arSession.pause()
        }
    }
    
    func continueCapture() {
        roomCaptureView.captureSession.run(configuration: configuration)
    }
    
    func redoCapture() {
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        
        var finalResults: CapturedRoom?
        
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        
        private var featuresPoints: [UInt64] = []
        
        private var worldMapCounter = 0
        
        static var save = false
        
        var r: CaptureViewContainer?
        
        @State var namedUrl: NamedURL
        
        init(namedUrl: NamedURL) {
            self.namedUrl = namedUrl
            self.currentMapName = namedUrl.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: CaptureViewContainer) { self.r = r }
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            session.arSession.getCurrentWorldMap(completionHandler: { worldMap, error in
                guard let worldMap = worldMap else {
                    print("Can't get current world map")
                    print(error!.localizedDescription)
                    return
                }
                self.worldMapCounter += 1
                NotificationCenter.default.post(name: .worldMapMessage, object: worldMap)
                if self.namedUrl is Room {NotificationCenter.default.post(name: .worlMapNewFeatures, object: worldMap.rawFeaturePoints.identifiers.difference(from: self.featuresPoints).count)
                    
                    NotificationCenter.default.post(name: .worldMapCounter, object: self.worldMapCounter)}
            })
        }
        
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            print(SessionDelegate.save)
            if !SessionDelegate.save { return }
            
            if let error {
                print("Error in captureSession(_:didEndWith:error:)")
                print(error)
            }
            
            Task {
                let name = currentMapName ?? "_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                let finalRoom = try! await self.roomBuilder.capturedRoom(from: data)
                
                print(namedUrl.url)
                
                saveJSONMap(finalRoom, name, at: namedUrl.url)
                
                saveUSDZMap(finalRoom, namedUrl.name, at: namedUrl.url)
                
                session.arSession.getCurrentWorldMap(completionHandler: { [self] worldMap, error in
                    if let m = worldMap {
                        if self.namedUrl is Room {saveARWorldMap(m, name, at: namedUrl.url)
                            let newIdentifiers = worldMap?.rawFeaturePoints.identifiers.difference(from: featuresPoints)
                            let addedIdentifiers = newIdentifiers!.compactMap { change -> UInt64? in
                                switch change {
                                case .insert(_, let identifier, _):
                                    return identifier
                                default:
                                    return nil
                                }
                            }
                            featuresPoints.append(contentsOf: addedIdentifiers)}
                        SessionDelegate.save = false
                    }
                })
            }
        }
        
        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
        
        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            return true
        }
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Gestione dello stato della mappa del mondo
        }
    }
}

struct CaptureViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        CaptureViewContainer(namedUrl: Room(name: "Sample Room", lastUpdate: Date(), referenceMarkers: [], transitionZones: [], sceneObjects: [], scene: nil, worldMap: nil, roomURL: URL(fileURLWithPath:"")))
    }
}
