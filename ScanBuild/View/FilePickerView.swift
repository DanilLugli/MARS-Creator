//
//  DocumentPickerView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 02/08/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.content, UTType.item], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let pickedURL = urls.first else { return }
            onPick(pickedURL)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}
