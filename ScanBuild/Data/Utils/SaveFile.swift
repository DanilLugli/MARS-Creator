import Foundation
import ARKit
import RoomPlan

func saveJSONMap(_ room: CapturedRoom, _ name: String) {
    do {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try jsonEncoder.encode(room)
        let saveURL = BuildingModel.SCANBUILD_ROOT.appendingPathComponent("JsonParametric").appendingPathComponent(name)
        try jsonData.write(to: saveURL)
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: true")
    } catch {
        print("Error = \(error)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: false")
    }
}

func saveUSDZMap(_ room: CapturedRoom, _ name: String, floorURL: URL) {
    do {
        // Costruisci il percorso per salvare il file USDZ e il file di metadata nella cartella "<floor_name>_Data"
        let dataDirectoryURL = floorURL.appendingPathComponent("\(floorURL.lastPathComponent)_Data")
        let saveURL = dataDirectoryURL.appendingPathComponent("MapUsdz").appendingPathComponent("\(name).usdz")
        
        if #available(iOS 17.0, *) {
            let metadataURL = dataDirectoryURL.appendingPathComponent("PlistMetadata").appendingPathComponent("\(name).plist")
            try room.export(
                to: saveURL,
                metadataURL: metadataURL,
                exportOptions: [.parametric, .mesh]
            )
        } else {
            try room.export(
                to: saveURL,
                exportOptions: [.parametric]
            )
        }
        
        NotificationCenter.default.post(name: .genericMessage, object: "saved USDZ: true")
    } catch {
        print("Error = \(error)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved USDZ: false")
    }
}
func saveARWorldMap(_ worldMap: ARWorldMap, _ name: String) {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: BuildingModel.SCANBUILD_ROOT.appendingPathComponent("Maps").appending(path: name), options: [.atomic])
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: true")
    } catch {
        print("Can't save map: \(error.localizedDescription)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: false")
    }
}
//func saveARWorldMap(_ worldMap: ARWorldMap, _ name: String) {
//    do {
//        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
//        try data.write(to: BuildingModel.SCANBUILD_ROOT.appendingPathComponent("Maps").appendingPathComponent(name), options: [.atomic])
//        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: true")
//    } catch {
//        print("Can't save map: \(error.localizedDescription)")
//        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: false")
//    }
//}
