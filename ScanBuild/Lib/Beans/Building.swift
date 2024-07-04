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
    var floors: [Floor]
    var date: String
    var fileURL: URL
    var connections = Connection()
    
    init(name: String, floors: [Floor], date: String, fileURL: URL = URL(fileURLWithPath: "")) {
        self.name = name
        self.floors = floors
        self.date = date
        self.fileURL = fileURL
    }
}
