import SwiftUI
import RoomPlan
import ARKit

struct FloorCaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView
    var arSession = ARSession()
    
    var sessionDelegate: SessionDelegate
    
    private let configuration: RoomCaptureSession.Configuration
    
    init(floor: Floor) {
        
        sessionDelegate = SessionDelegate(floor: floor)
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
    
    func stopCapture() {
        roomCaptureView.captureSession.stop()
        arSession.pause()
    }
    
    func redoCapture() {
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    func restartCapture() {

        stopCapture()

        sessionDelegate.roomBuilder = RoomBuilder(options: [.beautifyObjects])

        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }

    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        var finalResults: CapturedRoom?
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        @State var floor: Floor
        
        init(floor: Floor) {
            self.floor = floor
            self.currentMapName = floor.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: FloorCaptureViewContainer) {
        }
        
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            if let error = error {
                print("Error in captureSession(_:didEndWith:error:)")
                print(error)
                return
            }
            
            Task {
                do {
                    let name = currentMapName ?? "ScannedRoom_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                    let finalRoom = try await self.roomBuilder.capturedRoom(from: data)
                    
                    saveUSDZMap(finalRoom, name, at: floor.url)
                    
                    let usdzURL = floor.floorURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
                    floor.scene = try SCNScene(url: usdzURL)
                    floor.planimetry.loadFloorPlanimetry(borders: true, floor: floor)
                    
                    var seenNodeNames = Set<String>()
                    
                    floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
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
                    }).sorted(by: {
                        ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
                    })
                    ?? []
                    
                    
                } catch {
                    print("Error during room capturing or saving: \(error)")
                }
            }
        }
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
        
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    }
}
