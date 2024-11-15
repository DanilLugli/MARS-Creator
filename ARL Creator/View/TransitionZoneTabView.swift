//
//  TransitionZoneTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import Foundation
import SwiftUI

struct TransitionZoneTabView: View {
    @ObservedObject var room: Room
    @State private var searchText: String = ""

    var filteredTransitionZones: [TransitionZone] {
        if searchText.isEmpty {
            return room.transitionZones
        } else {
            return room.transitionZones.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            if room.transitionZones.isEmpty {
                Text("Add Transition Zone to \(room.name) with + icon.")
                    .foregroundColor(.gray)
                    .font(.headline)
                    .padding()
            } else {
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 50) {
                        ForEach(filteredTransitionZones, id: \.id) { transitionZone in
                            DefaultCardView(name: transitionZone.name, date: Date())
                                .padding()
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
