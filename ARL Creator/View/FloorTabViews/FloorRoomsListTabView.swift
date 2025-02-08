//
//  FloorRoomsListTabView.swift
//  ScanBuild
//
//  Created by Danil Lugli on 15/01/25.
//

import SwiftUI

struct RoomsListView: View {
    @ObservedObject var floor: Floor
    @ObservedObject var building: Building
    @Binding var searchText: String

    var body: some View {
        VStack {
            if floor.rooms.isEmpty {
                emptyStateView
            } else {
                searchBar
                roomListView
            }
        }
    }
    
    private var searchBar: some View {
        TextField("Search", text: $searchText)
            .padding(7)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity)
    }

    private var roomListView: some View {
        ScrollView {
            LazyVStack(spacing: 50) {
                ForEach(filteredRooms) { room in
                    NavigationLink(destination: RoomView(room: room, floor: floor, building: building)) {
                        RoomCardView(room: room, rowSize: 1, isSelected: false) 
                            .padding()
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        HStack {
            Text("Add Room with")
                .foregroundColor(.gray)
                .font(.headline)
            Image(systemName: "plus.circle")
                .foregroundColor(.gray)
            Text("icon")
                .foregroundColor(.gray)
                .font(.headline)
        }
    }

    private var filteredRooms: [Room] {
        if searchText.isEmpty {
            return floor.rooms
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            return floor.rooms
                .filter { $0.name.lowercased().contains(searchText.lowercased()) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
