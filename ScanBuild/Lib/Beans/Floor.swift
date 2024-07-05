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
    var date: String
    
    init(name: String, fileURL: URL, idBuilding: UUID, date: String) {
        self.name = name
        self.fileURL = fileURL
        self.idBuilding = idBuilding
        self.date = date
    }
}
