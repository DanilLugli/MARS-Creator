import Foundation
import AlertToast
import SwiftUI

struct RoomConnectionsTabView: View {
    @ObservedObject var building: Building
    @ObservedObject var room: Room
    @ObservedObject var floor: Floor
    @State private var searchText: String = ""

    // Stato per gestire il confirmationDialog
    @State private var showDeleteConfirmation = false
    @State private var showConnectionDeletedToast = false
    
    @State private var selectedConnection: AdjacentFloorsConnection? = nil

    var filteredConnections: [AdjacentFloorsConnection] {
        let connections = room.connections

        if searchText.isEmpty {
            return connections
        } else {
            return connections.filter { $0.targetRoom.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        VStack {
            if filteredConnections.isEmpty {
                VStack {
                    if building.floors.count >= 2 {
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
                    
                    if building.floors.count < 2 {
                        HStack {
                            Text("You need two or more floors to create a connection.")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
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
                                date: Date(),
                                rowSize: 1
                            )
                            .onTapGesture {
                                // Mostra il confirmationDialog
                                selectedConnection = connection
                                showDeleteConfirmation = true
                            }
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
        .confirmationDialog(
            "Do you want to delete this connection?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes, delete", role: .destructive) {
                if let connection = selectedConnection {
                   
                    let buildingModel = BuildingModel.getInstance()
                    room.deleteConnection(from: room, connectionName: connection.name, within: building)
                    showConnectionDeletedToast = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .toast(isPresenting: $showConnectionDeletedToast){
            AlertToast(displayMode: .banner(.slide), type: .regular, title: "Connection deleted successfully")
        }
    }
}
