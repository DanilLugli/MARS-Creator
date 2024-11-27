//
//  ConnectionsTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import Foundation
import SwiftUI

struct RoomConnectionsTabView: View {
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @State private var searchText: String = ""
    
    var filteredConnection: [TransitionZone] {
        let filteredZones = room.transitionZones.filter { transitionZone in
            transitionZone.connection != nil
        }
        
        if searchText.isEmpty {
            return filteredZones
        } else {
            return filteredZones.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            if filteredConnection.isEmpty {
                Text("Add a Connection for \(room.name) using the + icon.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 40) {
                        ForEach(filteredConnection, id: \.id) { transitionZone in
                            // Content here for displaying connections
                        }
                    }
                }
                .padding(.top, 15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
    }
}
