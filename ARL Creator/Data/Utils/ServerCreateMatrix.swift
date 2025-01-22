//
//  ServerCreateMatrix.swift
//  ScanBuild
//
//  Created by Danil Lugli on 01/08/24.
//

import Foundation
import SceneKit


func fetchAPIConversionLocalGlobal(localName: String, nodesList: [(SCNNode, SCNNode)]) async throws -> (HTTPURLResponse?, [String: Any]) {
    //0 local, 1 global
    for (node1, node2) in nodesList {
        let name1 = await node1.name ?? "Unnamed"
        let name2 = await node2.name ?? "Unnamed"
        
        print("\(name1):\(name2)")
    }
    var jsonObj = [String: [Any]]()
    jsonObj[localName] = []
    
    for n in nodesList {
        
        await print(n.0.simdWorldTransform)
        await print(n.0.transform)
        await print(n.1.simdWorldTransform)
        await print(n.1.transform)
        
        var _local: [String: Any] = [:]
        
        _local["scale"] = await [n.0.scale.x, n.0.scale.y, n.0.scale.z]
        _local["eulerY"] = await n.0.eulerAngles.y
        _local["position"] = await [
            [n.0.simdWorldTransform.columns.0.x, n.0.simdWorldTransform.columns.0.y, n.0.simdWorldTransform.columns.0.z, n.0.simdWorldTransform.columns.0.w],
            [n.0.simdWorldTransform.columns.1.x, n.0.simdWorldTransform.columns.1.y, n.0.simdWorldTransform.columns.1.z, n.0.simdWorldTransform.columns.1.w],
            [n.0.simdWorldTransform.columns.2.x, n.0.simdWorldTransform.columns.2.y, n.0.simdWorldTransform.columns.2.z, n.0.simdWorldTransform.columns.2.w],
            [n.0.simdWorldTransform.columns.3.x, n.0.simdWorldTransform.columns.3.y, n.0.simdWorldTransform.columns.3.z, n.0.simdWorldTransform.columns.3.w]
        ]
        
        
        var _global: [String: Any] = [:]
        _global["scale"] = await [n.1.scale.x, n.1.scale.y, n.1.scale.z]
        _global["eulerY"] = await n.1.eulerAngles.y
        _global["position"] = await [
            [n.1.simdWorldTransform.columns.0.x,
             n.1.simdWorldTransform.columns.0.y,
             n.1.simdWorldTransform.columns.0.z,
             n.1.simdWorldTransform.columns.0.w],
            [n.1.simdWorldTransform.columns.1.x, n.1.simdWorldTransform.columns.1.y, n.1.simdWorldTransform.columns.1.z, n.1.simdWorldTransform.columns.1.w],
            [n.1.simdWorldTransform.columns.2.x, n.1.simdWorldTransform.columns.2.y, n.1.simdWorldTransform.columns.2.z, n.1.simdWorldTransform.columns.2.w],
            [n.1.simdWorldTransform.columns.3.x, n.1.simdWorldTransform.columns.3.y, n.1.simdWorldTransform.columns.3.z, n.1.simdWorldTransform.columns.3.w]
        ]
        
        
        var e: [String: Any] = [:]
        e["local"] = _local
        e["global"] = _global
        jsonObj[localName]?.append(e)
    }
    
    //print(jsonObj)
    
    do {
        let data = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
        let s:String = String(data: data, encoding: .utf8)!
        //create the new url
        let url = URL(string: "https://develop.ewlab.di.unimi.it/musajapan/navigation/api/ransacalignment".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        //print(s)
        //print(jsonString)
        //create a new urlRequest passing the url
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = s.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        //run the request and retrieve both the data and the response of the call
        let (bodyres, response) = try await URLSession.shared.data(for: request)
        //print(response)
        guard response is HTTPURLResponse else {return (nil, ["err":"error converting -> response as? HTTPURLResponse"])}
        let res = response as! HTTPURLResponse
        do {
            _ = String(data: bodyres, encoding: .utf8)!.data(using: .utf8)!
            let resJson = try JSONSerialization.jsonObject(with: bodyres, options : .allowFragments) as! [String: Any]
            return (res, resJson)
        } catch {
            return (res, ["err": "error converting body response to JSON"])
        }
    } catch {
        return (nil, ["err": "error in sended data"])
    }
}


func printMatrix(matrix: [[Double]], decimal: Int) -> String {
    let roundedMatrix = matrix.map { $0.map { String(format: "%.\(decimal)f", $0) } }
    let maxLength = roundedMatrix.flatMap { $0 }.max { $0.count < $1.count }?.count ?? 0
    return roundedMatrix.map { $0.map { String(repeating: " ", count: maxLength - $0.count) + $0 }.joined(separator: " ") }.joined(separator: "\n")
}

func saveConversionGlobalLocal(_ conversions: [String: Any], _ URLFile: URL, _ floor: Floor) {
    var filteredDict = conversions.filter { $0.key.contains("TRANSFORMATION.LOCALTOGLOBAL") }
    filteredDict = Dictionary(uniqueKeysWithValues:filteredDict.map { key, value in
        let kMOD = String(key.split(separator: "_TRANSFORMATION.LOCALTOGLOBAL").first!)
        var vMOD = value as! [String: Any]
        vMOD = vMOD.filter{$0.key.contains("R_Y") || $0.key.contains("translation")}
        return (kMOD, vMOD)
    })
    
    updateJSONFile(filteredDict, URLFile, floor)
    
}

func updateJSONFile(_ dict: [String: Any], _ URLFile: URL, _ floor: Floor) {
    
    let fileManager = FileManager.default
    let fileURL = URLFile.appending(path: "\(floor.name).json")
    
    if fileManager.fileExists(atPath: fileURL.path) {
        do {
            var jsonData = try Data(contentsOf: fileURL)
            var json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            for (key, value) in dict {
                json[key] = value
            }
            jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            
            print("PRIMA: \(floor.associationMatrix)")
            // Ricarica il `floor` utilizzando la funzione `loadRoomPositionFromJson`
            if let updatedAssociationMatrix = loadRoomPositionFromJson(from: fileURL) {
                floor.associationMatrix = updatedAssociationMatrix
                print("Floor updated with new associationMatrix")
                
                print("DOPO: \(floor.associationMatrix)")
            } else {
                print("Failed to load associationMatrix from JSON.")
            }
            
            
        } catch {
            print("Errore_1")
            print(error.localizedDescription)
        }
    } else {
        do {

            let directory = fileURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }

            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
        } catch {
            print("Errore_2")
            print(error.localizedDescription)
        }
    }
}
