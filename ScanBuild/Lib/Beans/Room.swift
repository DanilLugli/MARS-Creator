import Foundation
import RoomPlan

struct Room: Identifiable, Codable, Hashable, CustomStringConvertible {
    var description: String {"\(floorName)>\(roomName)"}
    
    var id = UUID()
    var roomName: String
    var floorName: String
    var date: String
    var idFloor: UUID
    var fileURL: URL
    var associationMatrix: [[Double]] // Matrice di roto-traslazione
    var referenceMarkers: [ReferenceMarker]

    init(roomName: String, floorName: String, date: String, idFloor: UUID, fileURL: URL, associationMatrix: [[Double]], referenceMarkers: [ReferenceMarker]) {
        self.roomName = roomName
        self.floorName = floorName
        self.date = date
        self.idFloor = idFloor
        self.fileURL = fileURL
        self.associationMatrix = associationMatrix
        self.referenceMarkers = referenceMarkers
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

}
