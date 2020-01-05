//
//  CrudRoutePostResponseTests.swift
//  AsyncHTTPClient
//
//  Created by fnord on 1/4/20.
//

import FluentSQLiteDriver
import Fluent
import XCTVapor

final class CrudRoutePostResponseTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        app = Application()
        try! configure(app)
        
        try! app.migrator.setupIfNeeded().wait()
        try! app.migrator.prepareBatch().wait()
    }
    
    override func tearDown() {
        super.tearDown()
        
        try! app.migrator.revertAllBatches().wait()
    }
    
    func testPostBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            let newGalaxy = Galaxy(name: "Andromeda")
            
            try app.testable().test(.POST, "/galaxy", json: newGalaxy, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Galaxy.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Andromeda")
                XCTAssertEqual(decoded.id, 2)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 2)
                XCTAssert(newGalaxies.contains { $0.name == "Andromeda" })
                
                let newAndromeda = newGalaxies.first { $0.name == "Andromeda" }
                
                XCTAssertEqual(newAndromeda?.id, 2)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPostChildren() throws {
        app.crud(register: Galaxy.self) { (controller) in
            controller.crud(children: \.$planets)
        }
        
        do {
            let newGalaxy = Galaxy(name: "Andromeda")
            
            try app.testable().test(.POST, "/galaxy", json: newGalaxy, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Galaxy.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Andromeda")
                XCTAssertEqual(decoded.id, 2)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 2)
                XCTAssert(newGalaxies.contains { $0.name == "Andromeda" })
                
                let newAndromeda = newGalaxies.first { $0.name == "Andromeda" }
                
                XCTAssertEqual(newAndromeda?.id, 2)
            })
            
            let newPlanet = Planet(name: "Mars", galaxyID: 2)
            
            try app.testable().test(.POST, "/galaxy/1/planet", json: newPlanet, closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Planet.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Mars")
                XCTAssertEqual(decoded.id, 2)
                XCTAssertEqual(decoded.$galaxy.id, 2)

                
                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 2)
                XCTAssert(newPlanets.contains { $0.name == "Mars" })
                
                let newMars = newPlanets.first { $0.name == "Mars" }
                
                XCTAssertEqual(newMars?.id, 2)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPostParents() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(parent: \.$galaxy)
        }
        
        do {
            try app.testable().test(.POST, "/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.POST, "/planet/1/galaxy", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Galaxy.self, from: bodyBuffer)
                
                XCTAssert(decoded.name == "Milky Way")
                XCTAssert(decoded.id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPostSiblings() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(siblings: \.$tags)
        }
        
        app.crud(register: Tag.self) { controller in
            controller.crud(siblings: \.$planets)
        }
        
        do {
            try app.testable().test(.POST, "/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.POST, "/tag", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Tag].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.POST, "/planet/1/tag", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Tag].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == 1)
            })
            
            try app.testable().test(.POST, "/tag/1/planet", closure: { (resp) in
                XCTAssert(resp.status == .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode([Planet].self, from: bodyBuffer)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == 1)
            })
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    private func configure(_ app: Application) throws {
        // Serves files from `Public/` directory
        // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        // Configure SQLite database
        app.databases.use(.sqlite(), as: .sqlite)

        // Configure migrations
        app.migrations.add(GalaxyMigration())
        app.migrations.add(PlanetMigration())
        app.migrations.add(PlanetTagMigration())
        app.migrations.add(TagMigration())
       
        app.migrations.add(BaseGalaxySeeding())
        app.migrations.add(ChildSeeding())
        app.migrations.add(SiblingSeeding())
    }

    static var allTests = [
        ("testPublicable", testPostBase),
    ]
}

