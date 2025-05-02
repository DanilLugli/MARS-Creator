//
//  RoomCameraRMView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 20/01/25.
//

import SwiftUI
import UIKit

struct RoomCameraRMView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var room: Room
    
    @Environment(\.dismiss) private var dismiss
    //@State var showAddReferenceMarkerToast = false

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: RoomCameraRMView

        init(parent: RoomCameraRMView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.saveImageToFileSystem(image: image)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func saveImageToFileSystem(image: UIImage) {
        let fileManager = FileManager.default
        let referenceMarkerDir = room.roomURL.appendingPathComponent("ReferenceMarker")
        
        if !fileManager.fileExists(atPath: referenceMarkerDir.path) {
            do {
                try fileManager.createDirectory(at: referenceMarkerDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Errore creando la directory: \(error.localizedDescription)")
                return
            }
        }
        
        let newIndex = room.referenceMarkers.count + 1
        let newFileName = "\(room.name)_\(newIndex).jpg"
        let fileURL = referenceMarkerDir.appendingPathComponent(newFileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: fileURL)
            
            // Crea un nuovo marker usando il nome generato
            let newMarker = ReferenceMarker(
                _imagePath: fileURL,
                _imageName: "\(room.name)_\(newIndex)",
                _coordinates: simd_float3(x: 0, y: 0, z: 0),
                _rmUML: referenceMarkerDir,
                _physicalWidth: 0.0
            )
            
            room.referenceMarkers.append(newMarker)
            
            let markerDataURL = referenceMarkerDir.appendingPathComponent("Marker Data.json")
            newMarker.saveMarkerData(
                to: markerDataURL,
                old: newMarker.imageName,
                new: newMarker.imageName,
                size: 0.0,
                newCoordinates: newMarker.coordinates
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
}
