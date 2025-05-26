//
//  RoomTabsView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/02/25.
//

import Foundation
import SwiftUI

struct RoomTabsView: View {
    @Binding var selectedTab: Int
    var room: Room
    var floor: Floor
    var building: Building
    @Binding var hasAlertRoomPosition: Bool
    @Binding var hasAlertRoomMarkerWidth: Bool

    var onMarkerUpdated: () -> Void
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RoomPlanimetryTabView(room: room)
                .tabItem {
                    Label("Room Planimetry", systemImage: "map.fill")
                }
                .tag(0)

            RoomPositionTabView(room: room, floor: floor)
                .tabItem {
                    Label("Room Position", systemImage: "mappin.and.ellipse")
                }
                .tag(1)
                .badge(hasAlertRoomPosition ? "!" : nil)

            RoomMarkerTabView(room: room, onMarkerUpdated: onMarkerUpdated) // 🔹 Passiamo la funzione
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .tabItem {
                    Label("Marker", systemImage: "photo")
                }
                .tag(2)
                .badge(hasAlertRoomMarkerWidth ? "!" : nil)

            RoomConnectionsTabView(building: building, room: room, floor: floor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
                .tabItem {
                    Label("Connections", systemImage: "arrow.up.arrow.down")
                }
                .tag(3)
        }
    }
}
