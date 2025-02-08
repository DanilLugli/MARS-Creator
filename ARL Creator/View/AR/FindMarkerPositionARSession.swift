//
//  ARSessionMarkerPosition.swift
//  ScanBuild
//
//  Created by Danil Lugli on 06/02/25.
//

import Foundation
import SwiftUI
import ARKit
import RealityKit

struct FindMarkerPositionARSession: UIViewRepresentable {
    
    private let arView = ARSCNView()
    private var arSession: ARSession { arView.session }
    private var worldMapURL: URL
    private var markerPositions: [String: simd_float3] = [:]
    
    private var room: Room

    init(worldMapURL: URL, room: Room) {
           self.worldMapURL = worldMapURL
           self.room = room
       }
    func makeUIView(context: Context) -> ARSCNView {
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        arView.automaticallyUpdatesLighting = true
        arView.debugOptions = [.showFeaturePoints]

        loadWorldMap()
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    private func loadWorldMap() {
        do {
            let worldMapData = try Data(contentsOf: worldMapURL)
            let unarchiver = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: worldMapData)
            
            if let worldMap = unarchiver {
                let configuration = ARWorldTrackingConfiguration()
                configuration.initialWorldMap = worldMap
                configuration.detectionImages = loadReferenceImages() // ✅ Usa i marker della Room
                configuration.maximumNumberOfTrackedImages = room.referenceMarkers.count // ✅ Numero massimo di marker tracciabili
                
                arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                print("✅ ARWorldMap caricata con successo!")
            } else {
                print("⚠️ Errore: ARWorldMap non valida.")
            }
        } catch {
            print("❌ Impossibile caricare la ARWorldMap: \(error)")
        }
    }

    private func loadReferenceImages() -> Set<ARReferenceImage>? {
        var referenceImages: Set<ARReferenceImage> = []
        
//        for marker in room.referenceMarkers {
//            if let imageData = room.roomURL.appendingPathComponent("Reference Markers").appendingPathComponent("\(marker.imageName)"),
//               let uiImage = UIImage(data: imageData),
//               let cgImage = uiImage.cgImage {
//                
//                let referenceImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: marker.physicalWidth)
//                referenceImage.name = marker.imageName
//                referenceImages.insert(referenceImage)
//            }
//        }

        return referenceImages.isEmpty ? nil : referenceImages
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: FindMarkerPositionARSession
        private var trackingState: ARCamera.TrackingState = .notAvailable // 🔹 Tracking state attuale

        init(_ parent: FindMarkerPositionARSession) {
            self.parent = parent
            super.init()
        }

        // MARK: - Traccia la Posizione dell'iPhone in Tempo Reale
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let position = frame.camera.transform.columns.3
            let devicePosition = simd_float3(position.x, position.y, position.z)

            // ✅ Aggiorna lo stato di tracking attuale
            trackingState = frame.camera.trackingState

            print("📍 Posizione iPhone aggiornata: \(devicePosition) | Tracking: \(trackingStateToString(trackingState))")
        }

        // MARK: - Quando un Marker Viene Riconosciuto
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let imageAnchor = anchor as? ARImageAnchor else { return }
            let markerName = imageAnchor.referenceImage.name ?? "Unknown"
            let markerPosition = imageAnchor.transform.columns.3
            let markerSIMD = simd_float3(markerPosition.x, markerPosition.y, markerPosition.z)

            // ✅ Salva la posizione del marker solo se il trackingState è "Normal"
            if case .normal = trackingState {
                parent.markerPositions[markerName] = markerSIMD
                print("✅ Marker '\(markerName)' salvato alla posizione: \(markerSIMD)")
            } else {
                print("⚠️ Marker '\(markerName)' rilevato, ma ignorato (Tracking State: \(trackingStateToString(trackingState)))")
            }
        }

        // MARK: - Converti Tracking State in Stringa
        private func trackingStateToString(_ state: ARCamera.TrackingState) -> String {
            switch state {
            case .notAvailable:
                return "Not Available"
            case .limited(let reason):
                return "Limited (\(reason))"
            case .normal:
                return "Normal"
            }
        }
    }
}
