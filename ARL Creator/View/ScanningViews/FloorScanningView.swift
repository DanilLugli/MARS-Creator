import SwiftUI
import AlertToast
import ARKit
import RoomPlan

struct FloorScanningView: View {
    @State var floor: Floor
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worldMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var placeSquare = false
    
    @State var isScanningFloor = false
    @State var showScanningFloorCard = true
    
    @State var showCreateFloorPlanimetryToast = false
    @State var showDoneButton = false
    @State var showContinueScanButton = false
    @State var showCreateFloorPlanimetryButton = false
    
    @State var captureView: FloorCaptureViewContainer?
    
    @State private var dimensions: [String] = []
    @State var message = ""
    @State private var mapName: String = ""
    
    @Environment(\.dismiss) var dismiss

    init(floor: Floor) {
        self.floor = floor
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isScanningFloor, let captureView = captureView {
                    captureView
                        .edgesIgnoringSafeArea(.all)
                        .toolbarBackground(.hidden, for: .navigationBar) 
                }
                
                else {
                    
                    VStack{
                        Text("How to Scan a Floor")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    VStack{
                        Text("""
                                    • Scan **one room at a time** for better accuracy.
                                    • When you finish scanning a room, press **Done**.
                                    • To scan another room, press **Continue Scan**.
                                    • When all rooms are scanned, press **Create Floor** to generate the final planimetry.
                                    """)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        
                        Text("PRESS START TO SCAN \(floor.name)")
                            .foregroundColor(.gray)
                            .bold()
                    }
                    
                   
                }
                
                VStack {
//                    
//                    if let scene = floor.scene {
//                        SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
//                            .frame(height: 300)
//                            .background(Color.black.opacity(0.2))
//                            .cornerRadius(10)
//                            .padding()
//                            .overlay(
//                                Text("Preview of Captured Structure")
//                                    .font(.headline)
//                                    .foregroundColor(.white)
//                                    .padding(),
//                                alignment: .topLeading
//                            )
//                    }

                    VStack {
                        Spacer()

                        HStack {
                            
                            if showContinueScanButton {
                                Button(action: {
                                    captureView?.continueCapture()
                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                    showDoneButton = true
                                    showContinueScanButton = false
                                    showCreateFloorPlanimetryButton = false
                                }) {
                                    Text("Continue Scan")
                                        .font(.system(size: 16, weight: .bold))
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(30)
                                        .frame(maxWidth: 150)
                                }
                            }

                            Spacer()

                            VStack {
                                
                                if showDoneButton {
                                    Button(action: {
                                        captureView?.stopCapture(pauseARSession: false)
                                        showDoneButton = false
                                        showContinueScanButton = true
                                        showCreateFloorPlanimetryButton = true
                                    }) {
                                        Text("Done")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding()
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                            .frame(maxWidth: 100)
                                    }
                                    
                                }

                                if showCreateFloorPlanimetryButton {
                                    Button(action: {
                                        captureView?.stopCapture(pauseARSession: true)
                                        Task {
                                            await captureView?.sessionDelegate.generateCapturedStructureAndExport(to: floor.floorURL)
                                        }
                                        _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
                                        showCreateFloorPlanimetryToast = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            dismiss()
                                        }
                                    }) {
                                        Text("Save Floor")
                                            .font(.system(size: 16, weight: .bold))
                                            .padding()
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(30)
                                            //.frame(maxWidth: 150)
                                    }
                                }
                            }
                        }
                        .padding([.leading, .trailing, .bottom], 12)
                    }
                    
                    Spacer()
                    
                    if !isScanningFloor {
                        Button(action: {
                            isScanningFloor = true
                            captureView = FloorCaptureViewContainer(floor: floor)
                            showDoneButton = true
                            showContinueScanButton = false
                            showCreateFloorPlanimetryButton = false
                        }) {
                            Text("Start")
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .bold()
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(30)
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
                .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                    if let message = notification.object as? String {
                        self.message = message
                    }
                }
            }
            .background(Color.customBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(floor.name)
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .toast(isPresenting: $showCreateFloorPlanimetryToast) {
                AlertToast(type: .complete(Color.green), title: "Floor Planimetry created")
            }
        }
    }
}

struct FloorScanningView_Previews: PreviewProvider {
    static var previews: some View {
        FloorScanningView(floor: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
    }
}
//
//import SwiftUI
//import AlertToast
//import ARKit
//import RoomPlan
//import _SceneKit_SwiftUI
//
//struct FloorScanningView: View {
//    @State var floor: Floor
//    
//    @State private var messagesFromWorldMap: String = ""
//    @State private var worldMapNewFeatures: Int = 0
//    @State private var worldMapCounter: Int = 0
//    @State private var placeSquare = false
//    
//    @State var isScanningFloor = false
//    @State var showScanningFloorCard = true
//    
//    @State var showCreateFloorPlanimetryToast = false
//    @State var showDoneButton = false
//    @State var showContinueScanButton = false
//    @State var showCreateFloorPlanimetryButton = false
//    
//    @State var captureView: FloorCaptureViewContainer?
//    
//    @State private var dimensions: [String] = []
//    @State var message = ""
//    @State private var mapName: String = ""
//    
//    // Nuova variabile per mostrare la preview della SCNScene
//    @State private var showPreview: Bool = false
//    
//    @Environment(\.dismiss) var dismiss
//
//    init(floor: Floor) {
//        self.floor = floor
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // Se la scansione è attiva, mostriamo la captureView (AR)
//                if isScanningFloor, let captureView = captureView {
//                    captureView
//                        .edgesIgnoringSafeArea(.all)
//                        .toolbarBackground(.hidden, for: .navigationBar)
//                } else {
//                    // Altrimenti mostriamo istruzioni statiche
//                    VStack {
//                        Text("How to Scan a Floor")
//                            .font(.system(size: 24, weight: .bold))
//                            .foregroundColor(.gray)
//                        
//                        Image(systemName: "camera.viewfinder")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 70, height: 70)
//                            .foregroundColor(.gray)
//                        
//                        Spacer()
//                    }
//                    VStack {
//                        Text("""
//                        • Scan **one room at a time** for better accuracy.
//                        • When you finish scanning a room, press **Done**.
//                        • To scan another room, press **Continue Scan**.
//                        • When all rooms are scanned, press **Create Floor** to generate the final planimetry.
//                        """)
//                        .multilineTextAlignment(.leading)
//                        .padding()
//                        .foregroundColor(.gray)
//                        .font(.system(size: 16))
//                        
//                        Text("PRESS START TO SCAN \(floor.name)")
//                            .foregroundColor(.gray)
//                            .bold()
//                    }
//                }
//                
//                // Overlay dei pulsanti in basso
//                VStack {
//                    Spacer()
//
//                    HStack {
//                        if showContinueScanButton {
//                            Button(action: {
//                                // Nascondiamo la preview e riprendiamo la scansione
//                                showPreview = false
//                                captureView?.continueCapture()
//                                _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                showDoneButton = true
//                                showContinueScanButton = false
//                                showCreateFloorPlanimetryButton = false
//                            }) {
//                                Text("Continue Scan")
//                                    .font(.system(size: 16, weight: .bold))
//                                    .padding()
//                                    .background(Color.orange)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(30)
//                                    .frame(maxWidth: 150)
//                            }
//                        }
//                        
//                        Spacer()
//                        
//                        VStack {
//                            if showDoneButton {
//                                Button(action: {
//                                    // Quando premi "Done", fermiamo la scansione e mostriamo la preview
//                                    captureView?.stopCapture(pauseARSession: false)
//                                    showDoneButton = false
//                                    showContinueScanButton = true
//                                    showCreateFloorPlanimetryButton = true
//                                    // Impostiamo la flag per mostrare la preview
//                                    showPreview = true
//                                }) {
//                                    Text("Done")
//                                        .font(.system(size: 16, weight: .bold))
//                                        .padding()
//                                        .background(Color.green)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(30)
//                                        .frame(maxWidth: 100)
//                                }
//                            }
//                            
//                            if showCreateFloorPlanimetryButton {
//                                Button(action: {
//                                    captureView?.stopCapture(pauseARSession: true)
//                                    Task {
//                                        await captureView?.sessionDelegate.generateCapturedStructureAndExport(to: floor.floorURL)
//                                    }
//                                    _ = mapName.isEmpty ? "Map_\(Date().timeIntervalSince1970)" : mapName
//                                    showCreateFloorPlanimetryToast = true
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                                        dismiss()
//                                    }
//                                }) {
//                                    Text("Save Floor")
//                                        .font(.system(size: 16, weight: .bold))
//                                        .padding()
//                                        .background(Color.blue)
//                                        .foregroundColor(.white)
//                                        .cornerRadius(30)
//                                }
//                            }
//                        }
//                    }
//                    .padding([.leading, .trailing, .bottom], 12)
//                }
//                
//                // Pulsante "Start" per avviare la scansione
//                if !isScanningFloor {
//                    Button(action: {
//                        isScanningFloor = true
//                        captureView = FloorCaptureViewContainer(floor: floor)
//                        showDoneButton = true
//                        showContinueScanButton = false
//                        showCreateFloorPlanimetryButton = false
//                    }) {
//                        Text("Start")
//                            .font(.system(size: 18, weight: .bold, design: .default))
//                            .padding()
//                            .background(Color.green)
//                            .foregroundColor(.white)
//                            .cornerRadius(30)
//                    }
//                    .padding()
//                }
//                
//                if showPreview, let scene = floor.scene {
//                    ZStack {
//                        Color.black.opacity(0.8)
//                            .ignoresSafeArea()
//                        VStack {
//                            Text("Preview of Captured Structure")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .padding()
//                            
//                            SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
//                                .frame(height: 300)
//                                .background(Color.black.opacity(0.2))
//                                .cornerRadius(10)
//                                .padding()
//                                .onAppear {
//                                   
//                                    scene.rootNode.enumerateChildNodes { (node, _) in
//                                        if let nodeName = node.name?.lowercased(), nodeName.contains("floor") {
//                                            node.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
//                                        }
//                                    }
//                                }
//                            
//                            Button(action: {
//                               
//                                showPreview = false
//                            }) {
//                                Text("Close Preview")
//                                    .font(.system(size: 16, weight: .bold))
//                                    .padding()
//                                    .background(Color.white)
//                                    .foregroundColor(.black)
//                                    .cornerRadius(10)
//                            }
//                            .padding(.top, 10)
//                            
//                            Spacer()
//                        }
//                    }
//                    .transition(.opacity)
//                    .animation(.easeInOut, value: showPreview)
//                }
//            }
//            .background(Color.customBackground.ignoresSafeArea())
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text(floor.name)
//                        .font(.system(size: 26, weight: .heavy))
//                        .foregroundColor(.white)
//                }
//            }
//            .toast(isPresenting: $showCreateFloorPlanimetryToast) {
//                AlertToast(type: .complete(Color.green), title: "Floor Planimetry created")
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .worldMapCounter)) { notification in
//                if let counter = notification.object as? Int {
//                    self.worldMapCounter = counter
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .worldMapMessage)) { notification in
//                if let worldMap = notification.object as? ARWorldMap {
//                    self.messagesFromWorldMap = """
//                    features: \(worldMap.rawFeaturePoints.identifiers.count)
//                    """
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .worldMapNewFeatures)) { notification in
//                if let newFeatures = notification.object as? Int {
//                    self.worldMapNewFeatures = newFeatures
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
//                if let message = notification.object as? String {
//                    self.message = message
//                }
//            }
//        }
//    }
//}
//
//struct FloorScanningView_Previews: PreviewProvider {
//    static var previews: some View {
//        FloorScanningView(floor: Floor(_name: "Sample Floor", _lastUpdate: Date(), _planimetry: SCNViewContainer(), _associationMatrix: [:], _rooms: [], _sceneObjects: [], _scene: nil, _floorURL: URL(fileURLWithPath: "")))
//    }
//}
