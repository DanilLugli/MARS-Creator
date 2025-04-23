//
//  Logger.swift
//  ScanBuild
//
//  Created by Danil Lugli on 01/07/24.
//

struct Logger {
    private let tag: String
    
    init(tag: String) {
        self.tag = tag.uppercased()
    }
    
    func log(_ message: String) {
        print("\(self.tag): \(message)")
    }
}
