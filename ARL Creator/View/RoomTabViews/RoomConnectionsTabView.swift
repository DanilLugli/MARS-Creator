import Foundation
import SwiftUI

struct RoomConnectionsTabView: View {
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @State private var searchText: String = ""

    var filteredConnections: [AdjacentFloorsConnection] {
        let connections = room.connections // Ora accede direttamente alle connessioni della stanza

        if searchText.isEmpty {
            return connections
        } else {
            return connections.filter { $0.targetRoom.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            if filteredConnections.isEmpty {
                HStack {
                    HStack {
                        Text("Create Connection with")
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
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredConnections, id: \.id) { connection in
                            ListConnectionCardView(
                                floor: floor.name,
                                room: room.name,
                                targetFloor: connection.targetFloor,
                                targetRoom: connection.targetRoom,
                                altitudeDifference: connection.altitude,
                                exist: true,
                                date: Date(), // Puoi sostituirlo con una data reale se disponibile
                                rowSize: 1
                            )
                        }
                    }
                }
                .padding(.top, 15)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.customBackground)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Connections")
    }
}
