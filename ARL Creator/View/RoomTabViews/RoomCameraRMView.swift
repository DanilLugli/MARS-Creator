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
        let filename = room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("room_photo.jpg")
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        do {
            try data.write(to: filename)
            let newMarker = ReferenceMarker(
                _imagePath: room.roomURL.appendingPathComponent("ReferenceMarker").appendingPathComponent("room_photo.jpg"),
                _imageName: "room_photo.jpg",
                _coordinates: Coordinates(x: Float(Double.random(in: -100...100)), y: Float(Double.random(in: -100...100))),
                _rmUML: room.roomURL.appendingPathComponent("ReferenceMarker"),
                _physicalWidth: 0.0
            )
            room.referenceMarkers.append(newMarker)
            print("Image saved to: \(filename)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
            
        } catch {
            print("Error saving image: \(error.localizedDescription)")
        }
    }
}

//struct ContentView: View {
//    @State private var showCamera = false
//
//    var body: some View {
//        VStack {
//            Text("Room Camera")
//                .font(.headline)
//
//            Button("Take Photo") {
//                showCamera = true
//            }
//            .sheet(isPresented: $showCamera) {
//                RoomCameraRMView(isPresented: $showCamera)
//            }
//        }
//        .padding()
//    }
//}
//
//@main
//struct MyApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
