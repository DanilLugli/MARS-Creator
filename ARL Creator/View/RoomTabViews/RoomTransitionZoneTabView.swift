//
//  TransitionZoneTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/11/24.
//

import Foundation
import SwiftUI

struct RoomTransitionZoneTabView: View {
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
                HStack{
                    HStack{
                        Text("Add Transition Zone with")
                            .foregroundColor(.gray)
                            .font(.headline)
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.gray)
                        
                        Text("icon")
                            .foregroundColor(.gray)
                            .font(.headline)
                    }
                }
            } else {
                
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity)
                
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
