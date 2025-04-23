//
//  FloorAltitudeTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 13/01/25.
//

import SwiftUI
import ARKit
import RealityKit

struct FloorAltitudeTabView: View {
    
    @ObservedObject var building: Building
    @ObservedObject var floor: Floor
    
    @State private var selectedFloor: Floor?
    
    @State private var showARView = false // Stato per mostrare la ARView
    @Binding var altitudeY: Float // Usa un binding per sincronizzare l'altitudine
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {

            VStack {
                HStack{
                    Image(systemName: "exclamationmark.triangle")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.yellow)
                        .font(.largeTitle)
                    Text("To calculate the altitude, move from the starting Room to the destination Room after tapping \"Calculate Altitude.\"\nYou may also do the reverse.")
                        .foregroundColor(.gray)
                        .font(.headline)
                        .padding()
                }
                
                HStack{
                    VStack{
                        Image(systemName: "figure.walk.departure")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    Image(systemName: "figure.stairs")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.gray)
                        .font(.largeTitle)
                    Image(systemName: "figure.walk.arrival")
                        .scaleEffect(x: -1, y: 1) // Inverte l'icona orizzontalmente
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }.padding()
            }
            
            Spacer()
            
            Text(String(format: "Altitude: %.2f", floor.altitude))
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal)
            
            
            Spacer()
            
            Button(action: {
                showARView = true
            }) {
                Text(floor.altitude == 0 ? "Calculate Altitude" : "Re-Calculate Altitude")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .bold()
                    .padding()
//                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(30)
            }
            .padding(.bottom, 20)
            
        }
        .fullScreenCover(isPresented: $showARView) {
            ZStack {
                ARViewContainer(altitudeY: $altitudeY, onDismiss: {
                    floor.altitude = altitudeY
                    showARView = false
                }).ignoresSafeArea()
                
                VStack {
                    Spacer()
                    Text(String(format: "Altitude: %.2f", altitudeY))
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding()
                    
                    Button(action: {
                        showARView = false
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .bold()
                            .padding()
//                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .frame(maxWidth: 150) // Larghezza massima del bottone
                    }.padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}

// MARK: - ARViewContainer

struct ARViewContainer: UIViewControllerRepresentable {
    @Binding var altitudeY: Float 
    var onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController(altitudeY: $altitudeY, onDismiss: onDismiss)
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

// MARK: - ARViewController

class ARViewController: UIViewController, ARSessionDelegate {
    @Binding var altitudeY: Float
    var onDismiss: () -> Void
    
    init(altitudeY: Binding<Float>, onDismiss: @escaping () -> Void) {
        self._altitudeY = altitudeY
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arView = ARView(frame: .zero)
        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
        
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        
        view.addSubview(arView)
        arView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        altitudeY = cameraTransform.columns.3.y
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let arView = view.subviews.first(where: { $0 is ARView }) as? ARView {
            arView.session.pause() // Ferma esplicitamente la sessione AR
        }
        onDismiss()
    }
}
