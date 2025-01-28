import SwiftUI
import RoomPlan
import ARKit
import RealityKit

struct RoomCaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    var arSession = ARSession()
    var sessionDelegate: SessionDelegate
    let configuration: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()

    let roomCaptureView: RoomCaptureView
    
    init(room: Room) {
        
        sessionDelegate = SessionDelegate(room: room)
        
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
        sessionDelegate.currentMapName = sessionDelegate.room.name
        
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: pauseARSession)
        } else {
            roomCaptureView.captureSession.stop()
        }
    }
    
    func redoCapture() {
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    func stopCapture() {
        roomCaptureView.captureSession.stop()
        arSession.pause()
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        var finalResults: CapturedRoom?
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        private var featuresPoints: [UInt64] = []
        private var worldMapCounter = 0
        static var save = false
        var r: RoomCaptureViewContainer?
        @State var room: Room
        var previewVisualizer: VisualizeRoomViewContainer!
        
        init(room: Room) {
            self.room = room
            self.currentMapName = room.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: RoomCaptureViewContainer) {
            //self.r = r
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
                
                NotificationCenter.default.post(
                    name: .worldMapNewFeatures,
                    object: worldMap.rawFeaturePoints.identifiers.difference(from: self.featuresPoints).count
                )
                
                NotificationCenter.default.post(name: .worldMapCounter, object: self.worldMapCounter)
                
            }
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            //if !SessionDelegate.save { return }
            
            if let error = error {
                print("Error in captureSession(_:didEndWith:error:)")
                print(error)
                return
            }
            
            Task {
                do {
                    let name = currentMapName ?? "_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                    
                    let finalRoom = try await self.roomBuilder.capturedRoom(from: data)
                                        
                    saveJSONMap(finalRoom, room.name, at: room.roomURL)
                    saveUSDZMap(finalRoom, room.name, at: room.roomURL)
                    
                    session.arSession.getCurrentWorldMap { [self] worldMap, error in
                        if let worldMap = worldMap {

                                saveARWorldMap(worldMap, name, at: room.roomURL)

                                do{
                                    let usdzURL = room.roomURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(room.name).usdz")
                                    var seenNodeNames = Set<String>()
                                    
                                    room.scene = try SCNScene(url: usdzURL)
                                    room.planimetry.loadRoomPlanimetry(room: room, borders: true)
                                    room.sceneObjects = room.scene?.rootNode.childNodes(passingTest: { n, _ in
                                        if let nodeName = n.name {
                                            if seenNodeNames.contains(nodeName) {
                                                return false
                                            }
                                            guard n.geometry != nil else {
                                                return false
                                            }
                                            let isValidNode = nodeName != "Room" &&
                                                                nodeName != "Geom" &&
                                                                !nodeName.hasSuffix("_grp") &&
                                                                !nodeName.hasPrefix("unidentified") &&
                                                                !(nodeName.first?.isNumber ?? false) &&
                                                                !nodeName.hasPrefix("_")

                                            if isValidNode {
                                                seenNodeNames.insert(nodeName)
                                                return true
                                            }
                                        }
                                        return false
                                    }).sorted(by: { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }) ?? []
                                    
                                }
                                catch {
                                    print("Error creating SCNScene: \(error.localizedDescription)")
                                }
                                
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
                            
                            //SessionDelegate.save = false
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
            return true
        }
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
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


