import SwiftUI
import RoomPlan
import ARKit
import RealityKit

struct CaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    var arSession = ARSession()
    var sessionDelegate: SessionDelegate
    private let configuration: RoomCaptureSession.Configuration
    private let roomCaptureView: RoomCaptureView
    
    init(namedUrl: NamedURL) {
        
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
    
    mutating func stopCapture(pauseARSession: Bool) {
        print("CALL STOPCAPTURE CaptureViewContainer")
        SessionDelegate.save = !pauseARSession
        sessionDelegate.currentMapName = sessionDelegate.namedUrl.name
        
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: pauseARSession)
        } else {
            roomCaptureView.captureSession.stop()
        }
        
        if !pauseARSession {
            arSession.pause()

            let emptyConfiguration = ARWorldTrackingConfiguration()
            arSession.run(emptyConfiguration, options: [.resetTracking, .removeExistingAnchors])
            
            arSession.delegate = nil
            
            arSession = ARSession()
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
        var previewVisualizer: VisualizeRoomViewContainer!
        
        init(namedUrl: NamedURL) {
            self.namedUrl = namedUrl
            self.currentMapName = namedUrl.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: CaptureViewContainer) {
            self.r = r
        }
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            session.arSession.getCurrentWorldMap { worldMap, error in
                guard let worldMap = worldMap else {
                    print("Can't get current world map")
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    return
                }
                self.worldMapCounter += 1
                NotificationCenter.default.post(name: .worldMapMessage, object: worldMap)
                if self.namedUrl is Room {
                    NotificationCenter.default.post(
                        name: .worldMapNewFeatures,
                        object: worldMap.rawFeaturePoints.identifiers.difference(from: self.featuresPoints).count
                    )
                    
                    NotificationCenter.default.post(name: .worldMapCounter, object: self.worldMapCounter)
                }
            }
        }
        
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            print(SessionDelegate.save)
            if !SessionDelegate.save { return }
            
            if let error = error {
                print("Error in captureSession(_:didEndWith:error:)")
                print(error)
                return
            }
            
            Task {
                do {
                    let name = currentMapName ?? "_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                    let finalRoom = try! await self.roomBuilder.capturedRoom(from: data)
                    
                    print(namedUrl.url)
                    
                    saveJSONMap(finalRoom, name, at: namedUrl.url)
                    saveUSDZMap(finalRoom, namedUrl.name, at: namedUrl.url)
                    
                    session.arSession.getCurrentWorldMap { [self] worldMap, error in
                        if let worldMap = worldMap {
                            if self.namedUrl is Room {
                                saveARWorldMap(worldMap, name, at: namedUrl.url)
                                
                                let newIdentifiers = worldMap.rawFeaturePoints.identifiers.difference(from: featuresPoints)
                                let addedIdentifiers = newIdentifiers.compactMap { change -> UInt64? in
                                    switch change {
                                    case .insert(_, let identifier, _):
                                        return identifier
                                    default:
                                        return nil
                                    }
                                }
                                featuresPoints.append(contentsOf: addedIdentifiers)
                            }
                            SessionDelegate.save = false
                        } else if let error = error {
                            print("Error getting world map: \(error.localizedDescription)")
                        }
                    }
                } 
            }
        }
        
        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
        
        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            print("captureView")
            print(CapturedRoomData.self)
            return true
        }
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            print("captureView 2")
            print(CapturedRoom.self)
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Handle world map status updates
            switch frame.worldMappingStatus {
            case .notAvailable:
                NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Not available")
            case .limited:
                NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Available but has limited features")
            case .extending:
                NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Actively extending the map")
            case .mapped:
                NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Mapped the visible Area")
            @unknown default:
                NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Unknown state")
            }
        }
    }
}

struct CaptureViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        CaptureViewContainer(namedUrl: Room(_name: "Sample Room", _lastUpdate: Date(), _referenceMarkers: [], _transitionZones: [], _sceneObjects: [], _roomURL: URL(fileURLWithPath:"")))
    }
}

