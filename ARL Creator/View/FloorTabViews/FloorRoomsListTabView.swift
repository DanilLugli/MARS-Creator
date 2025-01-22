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
            } else {
                TextField("Search", text: $searchText)
                    .padding(7)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 13)
                    .frame(maxWidth: .infinity)

                ScrollView {
                    LazyVStack(spacing: 50) {
                        ForEach(filteredRooms, id: \.id) { room in
                            NavigationLink(destination: RoomView(room: room, floor: floor, building: building)) {
                                let isSelected = floor.isMatrixPresent(
                                    named: room.name,
                                    inFileAt: floor.floorURL.appendingPathComponent("\(floor.name).json")
                                )
                                RoomCardView(
                                    name: room.name,
                                    date: room.lastUpdate,
                                    position: isSelected,
                                    color: room.color,
                                    rowSize: 1,
                                    isSelected: false
                                )
                                .padding()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var filteredRooms: [Room] {
        if searchText.isEmpty {
            return floor.rooms
        } else {
            return floor.rooms.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}
