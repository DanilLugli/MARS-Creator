//
//  SomeFloorConnection.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class SameFloorConnection: Connection {
    private var _targetRoom: Room
    
    init(id: UUID, name: String, targetRoom: Room) {
        self._targetRoom = targetRoom
        super.init(id: id, name: name)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    var targetRoom: Room {
        get {
            return _targetRoom
        }
        set {
            _targetRoom = newValue
        }
    }
}
