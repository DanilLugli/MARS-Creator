//
//  ExportRoomViewContainer.swift
//  ScanBuild
//
//  Created by Danil Lugli on 09/07/24.
//

import Foundation
import SwiftUI
import RoomPlan
import ARKit


struct ExportRoomViewContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ExportRoomViewController {
        let viewController = ExportRoomViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ExportRoomViewController, context: Context) {}
}

class ExportRoomViewController: UIViewController, RoomCaptureViewDelegate {
    var roomCaptureView: RoomCaptureView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomCaptureView = RoomCaptureView(frame: self.view.bounds)
        roomCaptureView.delegate = self
        self.view.addSubview(roomCaptureView)
    }
    
    func roomCaptureView(_ view: RoomCaptureView, didUpdate session: RoomCaptureSession, with frame: ARFrame) {
        // Handle updates
    }
}
