//
//  Floor.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//

import Foundation
import ARKit


struct Floor: Identifiable, Codable, Hashable{
    var id = UUID()
    var name: String
    var fileURL: URL
    var idBuilding: UUID
    var rooms: [Room]
    var date: String
    
    init(name: String, fileURL: URL, idBuilding: UUID, rooms: [Room], date: String) {
        self.name = name
        self.fileURL = fileURL
        self.idBuilding = idBuilding
        self.rooms = rooms
        self.date = date
    }
}
