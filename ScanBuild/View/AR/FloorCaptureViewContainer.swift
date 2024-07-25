import SwiftUI
import RoomPlan
import ARKit

struct FloorCaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    private let floorCaptureView: RoomCaptureView
    private let arSession = ARSessionManager.shared.arSession
    
    var sessionDelegate: SessionDelegate
    
    private let configuration: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
    init(floor: Floor) {
        print("init floorCaptureView")
        sessionDelegate = SessionDelegate(floor: floor)
        if #available(iOS 17.0, *) {
            floorCaptureView = RoomCaptureView(frame: .zero, arSession: arSession)
        } else {
            floorCaptureView = RoomCaptureView(frame: .zero)
        }
        floorCaptureView.captureSession.delegate = sessionDelegate
        floorCaptureView.delegate = sessionDelegate
        floorCaptureView.captureSession.arSession.delegate = sessionDelegate
        sessionDelegate.setFloorCaptureView(self)
    }
    
    func makeUIView(context: Context) -> RoomCaptureView {
        floorCaptureView.captureSession.run(configuration: configuration)
        return floorCaptureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func stopCapture(pauseARSession: Bool) {
        SessionDelegate.save = !pauseARSession
        sessionDelegate.currentMapName = sessionDelegate.floor.name
        
        if #available(iOS 17.0, *) {
            floorCaptureView.captureSession.stop(pauseARSession: pauseARSession)
        } else {
            floorCaptureView.captureSession.stop()
        }
    }
    
    func continueCapture() {
        floorCaptureView.captureSession.run(configuration: configuration)
    }
    
    func redoCapture() {
        floorCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        
        var finalResults: CapturedRoom?
        
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        
        private var worldMapCounter = 0
        
        static var save = false
        
        var r: FloorCaptureViewContainer?
        
        @ObservedObject var floor: Floor
        
        init(floor: Floor) {
            self.floor = floor
            self.currentMapName = floor.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setFloorCaptureView(_ r: FloorCaptureViewContainer) { self.r = r }
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            // Gestione dell'aggiornamento della sessione di cattura
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
                
                print(floor.floorURL)
                
                saveJSONMap(finalRoom, name, at: floor.floorURL.appendingPathComponent(BuildingModel.FLOOR_DATA_FOLDER))
                
                saveUSDZMap(finalRoom, name, at: floor.floorURL.appendingPathComponent(BuildingModel.FLOOR_DATA_FOLDER))
                
                SessionDelegate.save = false
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

struct FloorCaptureViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        FloorCaptureViewContainer(floor: Floor(name: "", lastUpdate: Date(), planimetry: Image(""), associationMatrix: [:], rooms: [], sceneObjects: nil, scene: nil, sceneConfiguration: nil, floorURL: URL(fileURLWithPath: "")))
    }
}
