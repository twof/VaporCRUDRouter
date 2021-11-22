//
//  CrudRoutePostResponseTests.swift
//  AsyncHTTPClient
//
//  Created by fnord on 1/4/20.
//

import FluentSQLiteDriver
import Fluent
import XCTVapor
import Foundation

final class CrudRoutePutResponseTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        app = Application()
        try! configure(app)
        
        try! app.autoRevert().wait()
        try! app.autoMigrate().wait()
    }
    
    override func tearDown() {
        super.tearDown()
        
        app.shutdown()
    }
    
    func testPutBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            let galaxyId = BaseGalaxySeeding.milkyWayId
            let existingGalaxy = Galaxy(id: galaxyId, name: "Milky Way 2")
            
            try app.testable().test(.PUT, "/galaxy/\(galaxyId)", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Galaxy.self)
                
                XCTAssertEqual(decoded.name, "Milky Way 2")
                XCTAssertEqual(decoded.id, galaxyId)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 1)
                XCTAssert(newGalaxies.contains { $0.name == "Milky Way 2" })
                
                let newMilkyWay = newGalaxies.first { $0.name == "Milky Way 2" }
                
                XCTAssertEqual(newMilkyWay?.id, galaxyId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPutChildren() throws {
        app.crud(register: Galaxy.self, .only([.update])) { (controller) in
            controller.crud(children: \.$planets, .only([.update]))
        }
        
        do {
            let planetId = ChildSeeding.earthId
            let galaxyId = BaseGalaxySeeding.milkyWayId
            let existingPlanet = Planet(name: "Earth 2", galaxyID: galaxyId)

            // TODO: I think this test is wrong and shouldn't work
            try app.testable().test(.PUT, "/galaxy/\(galaxyId)/planet/\(planetId)", beforeRequest: { req in
                try req.content.encode(existingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth 2")
                XCTAssertEqual(decoded.id, planetId)
                XCTAssertEqual(decoded.$galaxy.id, galaxyId)

                
                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 1)
                XCTAssert(newPlanets.contains { $0.name == "Earth 2" })
                
                let newEarth = newPlanets.first { $0.name == "Earth 2" }
                
                XCTAssertEqual(newEarth?.id, planetId)
                XCTAssertEqual(newEarth?.$galaxy.id, BaseGalaxySeeding.milkyWayId)

                let parent = try Galaxy.find(BaseGalaxySeeding.milkyWayId, on: app.db).wait()
                let doesContainPlanet = try parent?.$planets.get(on: app.db).wait().contains { $0.name == decoded.name }
                XCTAssertEqual(doesContainPlanet, true)
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
            let planetId = ChildSeeding.earthId
            let galaxyId = BaseGalaxySeeding.milkyWayId
            let existingGalaxy = Galaxy(id: galaxyId, name: "Milky Way 2")
            
            try app.testable().test(.PUT, "/planet/\(planetId)/galaxy", beforeRequest: { req in
                try req.content.encode(existingGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)

                let decoded = try resp.content.decode(Galaxy.self)

                XCTAssertEqual(decoded.name, "Milky Way 2")
                XCTAssertEqual(decoded.id, galaxyId)

                let childPlanet = try Planet.find(planetId, on: app.db).wait()
                let parentGalaxy = try childPlanet?.$galaxy.get(on: app.db).wait()

                XCTAssertEqual(parentGalaxy?.name, "Milky Way 2")
                XCTAssertEqual(parentGalaxy?.id, galaxyId)
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
            let planetId = UUID()
            let existingPlanet = Planet(name: "Earth 2", galaxyID: planetId)
            
            try app.testable().test(.PUT, "/planet/\(planetId)", beforeRequest: { req in
                try req.content.encode(existingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth 2")
                XCTAssertEqual(decoded.id, planetId)
                // TODO: Pretty sure this is wront
                XCTAssertEqual(decoded.$galaxy.id, UUID())

                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 1)
                XCTAssert(newPlanets.contains { $0.name == "Earth 2" })
                
                let newMars = newPlanets.first { $0.name == "Earth 2" }

                // TODO: Rename variable
                XCTAssertEqual(newMars?.id, planetId)
            }

            let tagId = UUID()
            let existingTag = Tag(id: tagId, name: "Kind of Life Supporting")
            
            try app.testable().test(.PUT, "/tag/\(tagId)", beforeRequest: { req in
                try req.content.encode(existingTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Kind of Life Supporting")
                XCTAssertEqual(decoded.id, tagId)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 1)
                XCTAssert(newTags.contains { $0.name == "Kind of Life Supporting" })

                // TODO: rename variable
                let newMarsTag = newTags.first { $0.name == "Kind of Life Supporting" }
                
                XCTAssertEqual(newMarsTag?.id, tagId)
            }

            let otherTagId = UUID()
            let otherExistingTag = Tag(id: otherTagId, name: "Sort of Life Supporting")
            
            try app.testable().test(.PUT, "/planet/\(planetId)/tag/\(otherTagId)", beforeRequest: { req in
                try req.content.encode(otherExistingTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)

                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Sort of Life Supporting")
                XCTAssertEqual(decoded.id, otherTagId)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 1)
                XCTAssert(newTags.contains { $0.name == "Sort of Life Supporting" })

                // TODO: Rename variable
                let newEarthTag = newTags.first { $0.name == "Sort of Life Supporting" }
                
                XCTAssertEqual(newEarthTag?.id, otherTagId)
            }

            let galaxyId = UUID()
            let otherPlanetId = UUID()
            let otherExistingPlanet = Planet(id: otherPlanetId, name: "Earth 3", galaxyID: galaxyId)
            
            try app.testable().test(.PUT, "/tag/\(tagId)/planet/\(otherPlanetId)", beforeRequest: { req in
                try req.content.encode(otherExistingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Earth")
                XCTAssertEqual(decoded.id, otherPlanetId)
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

