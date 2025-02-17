//import SwiftUI
//import RoomPlan
//import ARKit
//
//struct FloorCaptureViewContainer: UIViewRepresentable {
//    typealias UIViewType = RoomCaptureView
//    
//    private let roomCaptureView: RoomCaptureView
//    var arSession = ARSession()
//    
//    var sessionDelegate: SessionDelegate
//    
//    private let configuration: RoomCaptureSession.Configuration
//    
//    init(floor: Floor) {
//        sessionDelegate = SessionDelegate(floor: floor)
//        configuration = RoomCaptureSession.Configuration()
//        
//        
//        if #available(iOS 17.0, *) {
//            roomCaptureView = RoomCaptureView(frame: .zero, arSession: arSession)
//        } else {
//            roomCaptureView = RoomCaptureView(frame: .zero)
//        }
//        
//        roomCaptureView.captureSession.delegate = sessionDelegate
//        roomCaptureView.delegate = sessionDelegate
//        roomCaptureView.captureSession.arSession.delegate = sessionDelegate
//        
//        sessionDelegate.setCaptureView(self)
//    }
//    
//    func makeUIView(context: Context) -> RoomCaptureView {
//        roomCaptureView.captureSession.run(configuration: configuration)
//        return roomCaptureView
//    }
//    
//    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
//    
//    func stopCapture(pauseARSession: Bool) {
//        
//        if #available(iOS 17.0, *) {
//            roomCaptureView.captureSession.stop(pauseARSession: pauseARSession)
//        } else {
//            roomCaptureView.captureSession.stop()
//        }
//        
//    }
//    
//    func continueCapture() {
//        roomCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
//    }
//
//    func redoLastCapture() {
//        _ = sessionDelegate.capturedRooms.popLast()
//        
//        let config = RoomCaptureSession.Configuration()
//        roomCaptureView.captureSession.run(configuration: config)
//    }
//    
//    func exportCapturedStructure(to destinationURL: URL ) async {
//        await sessionDelegate.generateCapturedStructureAndExport(to: destinationURL)
//    }
//    
//    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
//        
//        var currentMapName: String?
//        var capturedRooms: [CapturedRoom] = []
//        var finalResults: CapturedRoom?
//        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
//        @State var floor: Floor
//        
//        init(floor: Floor) {
//            self.floor = floor
//            self.currentMapName = floor.name
//            super.init(nibName: nil, bundle: nil)
//        }
//        
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//        
//        func setCaptureView(_ r: FloorCaptureViewContainer) {
//            
//        }
//        
//        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
//            guard error == nil else { return }
//
//            Task {
//                do {
//                    let finalRoom = try await roomBuilder.capturedRoom(from: data)
//                    
//                    capturedRooms.append(finalRoom)
//                    updateFloorSceneObjects()
//                } catch {
//                    print("Error processing captured room: \(error)")
//                }
//            }
//        }
//
//        private func updateFloorSceneObjects() {
//            var seenNodeNames = Set<String>()
//            floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { node, _ in
//                guard let nodeName = node.name else { return false }
//                
//                if seenNodeNames.contains(nodeName) { return false }
//                guard node.geometry != nil else { return false }
//
//                let isValidNode = nodeName != "Room" &&
//                                  nodeName != "Geom" &&
//                                  !nodeName.hasSuffix("_grp") &&
//                                  !nodeName.hasPrefix("unidentified") &&
//                                  !(nodeName.first?.isNumber ?? false) &&
//                                  !nodeName.hasPrefix("_")
//
//                if isValidNode {
//                    seenNodeNames.insert(nodeName)
//                    return true
//                }
//                return false
//            })
//            .sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
//        }
//        
//        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {}
//        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
//        func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
//        func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
//        func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
//        func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
//        
//        @available(iOS 17.0, *)
//        func generateCapturedStructureAndExport(to destinationURL: URL) async {
//            guard !capturedRooms.isEmpty else {
//                print("No rooms to combine.")
//                return
//            }
//            print("Destination: \(destinationURL)\n\n\n")
//            do {
//                
//                let structureBuilder = StructureBuilder(options: [.beautifyObjects])
//                let capturedStructure = try await structureBuilder.capturedStructure(from: capturedRooms)
//                
//                
//                let usdzURL = destinationURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(floor.name).usdz")
//                let plistURL = destinationURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(floor.name).plist")
//                
//                
//                try capturedStructure.export(to: usdzURL,
//                                             metadataURL: plistURL,
//                                             exportOptions: [.mesh])
//                
//                guard FileManager.default.fileExists(atPath: usdzURL.path) else {
//                    return
//                }
//                
//                floor.scene = try SCNScene(url: usdzURL)
//                var seenNodeNames = Set<String>()
//                floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
//                    if let nodeName = n.name {
//                        if seenNodeNames.contains(nodeName) {
//                            return false
//                        }
//
//                        guard n.geometry != nil else {
//                            return false
//                        }
//
//                        let isValidNode = nodeName != "Room" &&
//                                          nodeName != "Geom" &&
//                                          !nodeName.hasSuffix("_grp") &&
//                                          !nodeName.hasPrefix("unidentified") &&
//                                          !(nodeName.first?.isNumber ?? false) &&
//                                          !nodeName.hasPrefix("_")
//
//                        if isValidNode {
//                            seenNodeNames.insert(nodeName)
//                            return true
//                        }
//                    }
//                    
//                    return false
//                }).sorted(by: {
//                    ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending
//                })
//                ?? []
//                floor.planimetry.loadFloorPlanimetry(borders: true, floor: floor)
//                
//            } catch {
//                print("Error during structure generation, export, or scene loading: \(error.localizedDescription)")
//            }
//        }
//        
//        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
//            self.finalResults = processedResult
//        }
//        
//        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
//    }
//}

import SwiftUI
import RoomPlan
import ARKit

// MARK: - FloorCaptureViewContainer

struct FloorCaptureViewContainer: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView
    var arSession = ARSession()
    
    var sessionDelegate: SessionDelegate
    
    private let configuration: RoomCaptureSession.Configuration
    
    
    init(floor: Floor) {
        // Inizializziamo il delegate passando il floor
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
    
    // Questa funzione viene richiamata in "Save Floor" per l’esport finale
    func exportCapturedStructure(to destinationURL: URL ) async {
        await sessionDelegate.generateCapturedStructureAndExport(to: destinationURL)
    }
    
    // MARK: - SessionDelegate
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate, ObservableObject {
        
        var currentMapName: String?
        var capturedRooms: [CapturedRoom] = []
        var finalResults: CapturedRoom?
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        var floor: Floor
        @Published var capturedRoomsIsEmpty: Bool = true
        @Published var capturedRoomError: Bool = false
        
        init(floor: Floor) {
            self.floor = floor
            self.currentMapName = floor.name
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setCaptureView(_ r: FloorCaptureViewContainer) {
            // Se necessario, salva un riferimento alla view
        }
        
        // Quando la sessione termina una cattura di una room...
        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            if let error = error {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .genericMessage, object: error.localizedDescription)
                    }
                    return
                }

            Task {
                do {
                    let finalRoom = try await roomBuilder.capturedRoom(from: data)
                   
                    capturedRooms.append(finalRoom)
                    //updateFloorSceneObjects()
                    await updatePreviewScene()
                } catch {
                    print("Error processing captured room: \(error)")
                }
            }
        }

        /// Aggiorna la lista degli oggetti presenti nella scena del floor (filtraggio dei nodi)
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
        
        // Funzione già presente per l’esport finale (Save Floor)
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
                var seenNodeNames = Set<String>()
                floor.sceneObjects = floor.scene?.rootNode.childNodes(passingTest: { n, _ in
                    if let nodeName = n.name {
                        if seenNodeNames.contains(nodeName) {
                            return false
                        }
                        guard n.geometry != nil else { return false }
                        
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
                }) ?? []
                floor.planimetry.loadFloorPlanimetry(borders: true, floor: floor)
                
            } catch {
                print("Error during structure generation, export, or scene loading: \(error.localizedDescription)")
            }
        }
        
        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            self.finalResults = processedResult
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {}
        
        @available(iOS 17.0, *)
        func updatePreviewScene() async {
            guard !capturedRooms.isEmpty else {
                print("DEBUG: Nessuna room acquisita al momento.")
                return
            }
            
            print("DEBUG: updatePreviewScene chiamata con \(capturedRooms.count) room:")
            if capturedRooms.count > 1 { self.capturedRoomsIsEmpty = false}
            for (index, room) in capturedRooms.enumerated() {
                print("DEBUG: Room \(index + 1) -> \(room)")

                if let mirror = Mirror(reflecting: room).children.first(where: { $0.label == "identifier" }),
                   let identifier = mirror.value as? String {
                    print("DEBUG: Room \(index + 1) identifier: \(identifier)")
                } else {
                    print("DEBUG: Room \(index + 1) non fornisce un identifier univoco.")
                }
            }
            
            do {
                let structureBuilder = StructureBuilder(options: [.beautifyObjects])
                print("DEBUG: Creazione della capturedStructure con \(capturedRooms.count) room...")
                let capturedStructure = try await structureBuilder.capturedStructure(from: capturedRooms)
                print("DEBUG: capturedStructure creata correttamente.")
                
                let tempDirectory = FileManager.default.temporaryDirectory
                let usdzURL = tempDirectory.appendingPathComponent("\(floor.name)_preview.usdz")
                let plistURL = tempDirectory.appendingPathComponent("\(floor.name)_preview.plist")
                
                print("DEBUG: Esportazione della capturedStructure in \(usdzURL.path)")
                try capturedStructure.export(to: usdzURL, metadataURL: plistURL, exportOptions: [.mesh])
                
                if FileManager.default.fileExists(atPath: usdzURL.path) {
                    print("DEBUG: File USDZ trovato. Caricamento della scena da \(usdzURL.path)")
                    let scene = try SCNScene(url: usdzURL)
                    DispatchQueue.main.async {
                        self.floor.scene = scene
                        self.updateFloorSceneObjects()
                        print("DEBUG: floor.scene e floor.sceneObjects aggiornati con \(self.capturedRooms.count) room.")
                    }
                } else {
                    print("DEBUG: File USDZ non trovato in \(usdzURL.path)")
                }
            } catch {
                print("DEBUG: Errore nell'aggiornamento della preview: \(error)")
            }
        }
    }
}

