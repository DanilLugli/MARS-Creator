//
//  ConnectionTests.swift
//  ScanBuildUITests
//
//  Created by Danil Lugli on 03/07/24.
//

import XCTest
@testable import ScanBuild

final class ConnectionTests: XCTestCase {

    var connection: Connection!

    override func setUpWithError() throws {
        connection = Connection()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        connection = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // Test per la creazione di una connessione
    func testCreateConnection() throws {
        connection.addRoomToConnection(connectionName: "Floor_1>Room_8")
        connection.addRoomToConnection(connectionName: "Floor_0>Room_5")

        connection.createConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5")

        XCTAssertTrue(connection.getConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5"))
    }

    // Test per l'aggiunta di una stanza alla lista delle etichette e aggiornamento della matrice
    func testAddRoomToConnection() throws {
        connection.addRoomToConnection(connectionName: "Floor_1>Room_8")

        XCTAssertEqual(connection.getConnectedRooms(connectionName: "Floor_1>Room_8").count, 0)
        XCTAssertTrue(connection.getConnectedRooms(connectionName: "Floor_1>Room_8").isEmpty)
    }

    // Test per la cancellazione di una connessione
    func testDeleteConnection() throws {
        connection.addRoomToConnection(connectionName: "Floor_1>Room_8")
        connection.addRoomToConnection(connectionName: "Floor_0>Room_5")

        connection.createConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5")
        XCTAssertTrue(connection.getConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5"))

        connection.deleteConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5")
        XCTAssertFalse(connection.getConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5"))
    }

    // Test per verificare se esiste una connessione tra due stanze
    func testGetConnection() throws {
        connection.addRoomToConnection(connectionName: "Floor_1>Room_8")
        connection.addRoomToConnection(connectionName: "Floor_0>Room_5")

        connection.createConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5")
        XCTAssertTrue(connection.getConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5"))

        XCTAssertFalse(connection.getConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_2>Room_9"))
    }

    // Test per ottenere una lista di tutte le stanze collegate a una stanza specifica
    func testGetConnectedRooms() throws {
        connection.addRoomToConnection(connectionName: "Floor_1>Room_8")
        connection.addRoomToConnection(connectionName: "Floor_0>Room_5")
        connection.addRoomToConnection(connectionName: "Floor_2>Room_9")

        connection.createConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_0>Room_5")
        connection.createConnection(connectionName1: "Floor_1>Room_8", connectionName2: "Floor_2>Room_9")

        let connectedRooms = connection.getConnectedRooms(connectionName: "Floor_1>Room_8")
        XCTAssertEqual(connectedRooms.count, 2)
        XCTAssertTrue(connectedRooms.contains("Floor_0>Room_5"))
        XCTAssertTrue(connectedRooms.contains("Floor_2>Room_9"))
    }
}
