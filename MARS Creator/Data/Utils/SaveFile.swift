import Foundation
import ARKit
import RoomPlan

func saveJSONMap(_ room: CapturedRoom, _ name: String, at url: URL) {
    do {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try jsonEncoder.encode(room)
        let saveURL = url.appendingPathComponent("JsonParametric").appendingPathComponent(name).appendingPathExtension("json")
        try jsonData.write(to: saveURL)
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: true")
    } catch {
        print("Error = \(error)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: false")
    }
}

func saveARWorldMap(_ worldMap: ARWorldMap, _ name: String, at url: URL) {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        let saveURL = url.appendingPathComponent("Maps").appendingPathComponent(name).appendingPathExtension("map")
        try data.write(to: saveURL, options: [.atomic])
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: true")
    } catch {
        print("Can't save map: \(error.localizedDescription)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: false")
    }
}

func saveUSDZMap(_ room: CapturedRoom, _ name: String, at url: URL) {
    do {
        let dataDirectoryURL = url
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
