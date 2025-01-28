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
    
    func stopCapture(pauseARSession: Bool) {
        
        if #available(iOS 17.0, *) {
            roomCaptureView.captureSession.stop(pauseARSession: pauseARSession)
        } else {
            roomCaptureView.captureSession.stop()
        }
        
    }
    
    func continueCapture() {
        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }

    func redoLastCapture() {
        _ = sessionDelegate.capturedRooms.popLast()
        
        let config = RoomCaptureSession.Configuration()
        roomCaptureView.captureSession.run(configuration: config)
    }
    
    func exportCapturedStructure(to destinationURL: URL ) async {
        await sessionDelegate.generateCapturedStructureAndExport(to: destinationURL)
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        var capturedRooms: [CapturedRoom] = []
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
            guard error == nil else { return }

            Task {
                do {
                    let finalRoom = try await roomBuilder.capturedRoom(from: data)
                    
                    capturedRooms.append(finalRoom)
                    updateFloorSceneObjects()
                } catch {
                    print("Error processing captured room: \(error)")
                }
            }
        }

        private func updateFloorSceneObjects() {
            var seenNodeNames = Set<String>()
            floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { node, _ in
                guard let nodeName = node.name else { return false }
                
                if seenNodeNames.contains(nodeName) { return false }
                guard node.geometry != nil else { return false }

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
                return false
            })
            .sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
        }
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
        
        @available(iOS 17.0, *)
        func generateCapturedStructureAndExport(to destinationURL: URL) async {
            guard !capturedRooms.isEmpty else {
                print("No rooms to combine.")
                return
            }
            print("Destination: \(destinationURL)\n\n\n")
            do {
                
                let structureBuilder = StructureBuilder(options: [.beautifyObjects])
                let capturedStructure = try await structureBuilder.capturedStructure(from: capturedRooms)
                
                
                let usdzURL = destinationURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
                let plistURL = destinationURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(floor.name).plist")
                
                
                try capturedStructure.export(to: usdzURL,
                                             metadataURL: plistURL,
                                             exportOptions: [.mesh])
                
                guard FileManager.default.fileExists(atPath: usdzURL.path) else {
                    return
                }
                
                floor.scene = try SCNScene(url: usdzURL)
                floor.planimetry.loadFloorPlanimetry(borders: true, floor: floor)
                
            } catch {
                print("Error during structure generation, export, or scene loading: \(error.localizedDescription)")
            }
        }
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
    }
}
