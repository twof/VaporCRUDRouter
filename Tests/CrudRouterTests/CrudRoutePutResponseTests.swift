//
//  CrudRoutePostResponseTests.swift
//  AsyncHTTPClient
//
//  Created by fnord on 1/4/20.
//

import FluentSQLiteDriver
import Fluent
import XCTVapor

final class CrudRoutePutResponseTests: XCTestCase {
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
    
    func testPutBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            let existingGalaxy = Galaxy(id: 1, name: "Milky Way 2")
            
            try app.testable().test(.PUT, "/galaxy/1", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Galaxy.self)
                
                XCTAssertEqual(decoded.name, "Milky Way 2")
                XCTAssertEqual(decoded.id, 1)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 1)
                XCTAssert(newGalaxies.contains { $0.name == "Milky Way 2" })
                
                let newMilkyWay = newGalaxies.first { $0.name == "Milky Way 2" }
                
                XCTAssertEqual(newMilkyWay?.id, 1)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPutChildren() throws {
        app.crud(register: Galaxy.self) { (controller) in
            controller.crud(children: \.$planets)
        }
        
        do {
            let existingGalaxy = Galaxy(id: 1, name: "Milky Way 2")
            
            try app.testable().test(.PUT, "/galaxy/1", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Galaxy.self)
                
                XCTAssertEqual(decoded.name, "Milky Way 2")
                XCTAssertEqual(decoded.id, 1)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 1)
                XCTAssert(newGalaxies.contains { $0.name == "Milky Way 2" })
                
                let newAndromeda = newGalaxies.first { $0.name == "Milky Way 2" }
                
                XCTAssertEqual(newAndromeda?.id, 1)
            }
            
            let existingPlanet = Planet(name: "Earth 2", galaxyID: 1)
            
            try app.testable().test(.PUT, "/galaxy/1/planet/", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth 2")
                XCTAssertEqual(decoded.id, 1)
                XCTAssertEqual(decoded.$galaxy.id, 1)

                
                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 2)
                XCTAssert(newPlanets.contains { $0.name == "Earth 2" })
                
                let newEarth = newPlanets.first { $0.name == "Earth 2" }
                
                XCTAssertEqual(newEarth?.id, 1)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPutParents() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(parent: \.$galaxy)
        }
        
        do {
            let existingPlanet = Planet(name: "Earth 2", galaxyID: 1)
            
            try app.testable().test(.PUT, "/planet/1", beforeRequest: { req in
                try req.content.encode(existingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
               
                let decoded = try resp.content.decode(Planet.self)
               
                XCTAssertEqual(decoded.name, "Earth 2")
                XCTAssertEqual(decoded.id, 1)
                XCTAssertEqual(decoded.$galaxy.id, 1)

               
                let newPlanets = try app.db.query(Planet.self).all().wait()
               
                XCTAssertEqual(newPlanets.count, 1)
                XCTAssert(newPlanets.contains { $0.name == "Earth 2" })
               
                let newMars = newPlanets.first { $0.name == "Earth 2" }
               
                XCTAssertEqual(newMars?.id, 1)
            }
            
            let existingGalaxy = Galaxy(id: 1, name: "Milky Way 2")
            
            try app.testable().test(.PUT, "/planet/1/galaxy", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .notFound)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPutSiblings() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(siblings: \.$tags)
        }
        
        app.crud(register: Tag.self) { controller in
            controller.crud(siblings: \.$planets)
        }
        
        do {
            let existingPlanet = Planet(name: "Earth 2", galaxyID: 1)
            
            try app.testable().test(.PUT, "/planet/1", beforeRequest: { req in
                try req.content.encode(existingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth 2")
                XCTAssertEqual(decoded.id, 1)
                XCTAssertEqual(decoded.$galaxy.id, 1)

                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 1)
                XCTAssert(newPlanets.contains { $0.name == "Earth 2" })
                
                let newMars = newPlanets.first { $0.name == "Earth 2" }
                
                XCTAssertEqual(newMars?.id, 1)
            }
            
            let existingTag = Tag(id: 1, name: "Kind of Life Supporting")
            
            try app.testable().test(.PUT, "/tag/1", beforeRequest: { req in
                try req.content.encode(existingTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Kind of Life Supporting")
                XCTAssertEqual(decoded.id, 1)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 1)
                XCTAssert(newTags.contains { $0.name == "Kind of Life Supporting" })
                
                let newMarsTag = newTags.first { $0.name == "Kind of Life Supporting" }
                
                XCTAssertEqual(newMarsTag?.id, 1)
            }
            
            let otherExistingTag = Tag(id: 3, name: "Sort of Life Supporting")
            
            try app.testable().test(.PUT, "/planet/1/tag/1", beforeRequest: { req in
                try req.content.encode(otherExistingTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)

                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Sort of Life Supporting")
                XCTAssertEqual(decoded.id, 1)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 1)
                XCTAssert(newTags.contains { $0.name == "Sort of Life Supporting" })
                
                let newEarthTag = newTags.first { $0.name == "Sort of Life Supporting" }
                
                XCTAssertEqual(newEarthTag?.id, 1)
            }
            
            let otherExistingPlanet = Planet(name: "Earth 3", galaxyID: 1)
            
            try app.testable().test(.PUT, "/tag/1/planet/1", beforeRequest: { req in
                try req.content.encode(otherExistingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth")
                XCTAssertEqual(decoded.id, 1)
            }
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
        ("testPublicable", testPutBase),
    ]
}

