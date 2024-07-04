import Foundation
import RoomPlan

struct Room: Identifiable, Codable, Hashable, CustomStringConvertible {
    var description: String {"\(floorName)>\(roomName)"}
    
    var id = UUID()
    var roomName: String
    var floorName: String
    var idFloor: UUID
    var fileURL: URL
    var associationMatrix: [[Double]] // Matrice di roto-traslazione
    var referenceMarkers: [ReferenceMarker]
    var transitionZones: [TransitionZone] = []

    init(roomName: String, floorName: String, idFloor: UUID, fileURL: URL, associationMatrix: [[Double]], referenceMarkers: [ReferenceMarker], transitionZones: [TransitionZone]) {
        self.roomName = roomName
        self.floorName = floorName
        self.fileURL = fileURL
        self.idFloor = idFloor
        self.associationMatrix = associationMatrix
        self.referenceMarkers = referenceMarkers
        self.transitionZones = transitionZones
    }

    struct ReferenceMarker: Identifiable, Codable, Hashable {
        var id = UUID()
        var image: String // Path dell'immagine o nome dell'immagine
        var dimension_x: Double
        var dimension_y: Double

        init(image: String, dimension_x: Double, dimension_y: Double) {
            self.image = image
            self.dimension_x = dimension_x
            self.dimension_y = dimension_y
        }
    }

    struct TransitionZone: Identifiable, Codable, Hashable {
        var id = UUID()
        var xMin: Double
        var xMax: Double
        var yMin: Double
        var yMax: Double

        init(xMin: Double, xMax: Double, yMin: Double, yMax: Double) {
            self.xMin = xMin
            self.xMax = xMax
            self.yMin = yMin
            self.yMax = yMax
        }
    }
}
