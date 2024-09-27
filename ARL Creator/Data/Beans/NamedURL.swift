//
//  NamedURL.swift
//  ScanBuild
//
//  Created by Danil Lugli on 25/07/24.
//

import Foundation

protocol NamedURL {
    var name: String { get }
    var url: URL { get }
}
