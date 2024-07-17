//
//  AdjacentFloorsConnection.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class AdjacentFloorsConnection: Connection {
    private var _targetFloor: Floor
    private var _targetRoom: Room
    
    init(id: UUID, name: String, targetFloor: Floor, targetRoom: Room) {
        self._targetFloor = targetFloor
        self._targetRoom = targetRoom
        super.init(id: id, name: name)
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    var targetFloor: Floor {
        get {
            return _targetFloor
        }
        set {
            _targetFloor = newValue
        }
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
