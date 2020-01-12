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
                XCTAssertEqual(resp.status, .ok)
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
            let newPlanet = Planet(name: "Mars", galaxyID: 2)
            
            try app.testable().test(.POST, "/planet", json: newPlanet, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
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
            
            let newGalaxy = Galaxy(name: "Andromeda")
            
            try app.testable().test(.POST, "/planet/1/galaxy", json: newGalaxy, closure: { (resp) in
                XCTAssertEqual(resp.status, .notFound)
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
            let newPlanet = Planet(name: "Mars", galaxyID: 2)
            
            try app.testable().test(.POST, "/planet", json: newPlanet, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
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
            
            let newTag = Tag(id: 2, name: "Red")
            
            try app.testable().test(.POST, "/tag", json: newTag, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Tag.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Red")
                XCTAssertEqual(decoded.id, 2)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 2)
                XCTAssert(newTags.contains { $0.name == "Red" })
                
                let newMarsTag = newTags.first { $0.name == "Red" }
                
                XCTAssertEqual(newMarsTag?.id, 2)
            })
            
            let otherNewTag = Tag(id: 3, name: "Uninhabitable")
            
            try app.testable().test(.POST, "/planet/2/tag", json: otherNewTag, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Tag.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Uninhabitable")
                XCTAssertEqual(decoded.id, 3)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 2)
                XCTAssert(newTags.contains { $0.name == "Red" })
                
                let newMarsTag = newTags.first { $0.name == "Red" }
                
                XCTAssertEqual(newMarsTag?.id, 2)
            })
            
            let otherNewPlanet = Planet(id: 3, name: "Venus", galaxyID: 2)
            
            try app.testable().test(.POST, "/tag/2/planet", json: otherNewPlanet, closure: { (resp) in
                XCTAssertEqual(resp.status, .ok)
                guard let bodyBuffer = resp.body.buffer else { XCTFail(); return }
                
                let decoded = try JSONDecoder().decode(Planet.self, from: bodyBuffer)
                
                XCTAssertEqual(decoded.name, "Venus")
                XCTAssertEqual(decoded.id, 3)
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

