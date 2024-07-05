//
//  Building.swift
//  ScanBuild
//
//  Created by Danil Lugli on 26/06/24.
//

import Foundation

struct Building: Identifiable, Codable, Hashable{
    var id = UUID()
    var name: String
    var date: String
    var fileURL: URL
    var connections = Connection()
    
    init (name: String, date: String, fileURL: URL, connections: Connection = Connection()) {
        self.name = name
        self.date = date
        self.fileURL = fileURL
        self.connections = connections
    }
}
