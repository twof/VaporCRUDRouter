import FluentSQLiteDriver
import Fluent
import XCTVapor
import Foundation

final class CrudRoutePostResponseTests: XCTestCase {
    var app: Application!
    
    override func setUp() {
        super.setUp()
        
        app = Application(.testing)
        try! configure(app)

        try! app.autoRevert().wait()
        try! app.autoMigrate().wait()
    }
    
    override func tearDown() {
        super.tearDown()
        app.shutdown()
    }
    
    func testPostBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            let newGalaxyId = UUID()
            let newGalaxy = Galaxy(id: newGalaxyId, name: "Andromeda")
            try app.testable().test(.POST, "/galaxy", beforeRequest: { req in
                try req.content.encode(newGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)

                let decoded = try resp.content.decode(Galaxy.self)

                XCTAssertEqual(decoded.name, "Andromeda")
                XCTAssertEqual(decoded.id, newGalaxyId)

                let newGalaxies = try app.db.query(Galaxy.self).all().wait()

                XCTAssertEqual(newGalaxies.count, 2)
                XCTAssert(newGalaxies.contains { $0.name == "Andromeda" })

                let newAndromeda = newGalaxies.first { $0.name == "Andromeda" }

                XCTAssertEqual(newAndromeda?.id, newGalaxyId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPostChildren() throws {
        app.crud(register: Galaxy.self) { (controller) in
            controller.crud(children: \.$planets)
        }
        
        do {
            let newGalaxyId = UUID()
            let newGalaxy = Galaxy(id: newGalaxyId, name: "Andromeda")
            
            try app.testable().test(.POST, "/galaxy", beforeRequest: { req in
                try req.content.encode(newGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Galaxy.self)
                
                XCTAssertEqual(decoded.name, "Andromeda")
                XCTAssertEqual(decoded.id, newGalaxyId)
                
                let newGalaxies = try app.db.query(Galaxy.self).all().wait()
                
                XCTAssertEqual(newGalaxies.count, 2)
                XCTAssert(newGalaxies.contains { $0.name == "Andromeda" })
                
                let newAndromeda = newGalaxies.first { $0.name == "Andromeda" }
                
                XCTAssertEqual(newAndromeda?.id, newGalaxyId)
            }

            let newPlanetId = UUID()
            let newPlanet = Planet(id: newPlanetId, name: "Mars", galaxyID: newGalaxyId)
            
            try app.testable().test(.POST, "/galaxy/\(BaseGalaxySeeding.milkyWayId)/planet", beforeRequest: { req in
                try req.content.encode(newPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Mars")
                XCTAssertEqual(decoded.id, newPlanetId)
                XCTAssertEqual(decoded.$galaxy.id, BaseGalaxySeeding.milkyWayId)

                
                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 2)
                XCTAssert(newPlanets.contains { $0.name == "Mars" })
                
                let newMars = newPlanets.first { $0.name == "Mars" }
                
                XCTAssertEqual(newMars?.id, newPlanetId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testPostParents() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(parent: \.$galaxy)
        }
        
        do {
            let newGalaxyId = UUID()
            let newPlanetId = UUID()
            let newPlanet = Planet(id: newPlanetId, name: "Mars", galaxyID: newGalaxyId)
            
            try app.testable().test(.POST, "/planet", beforeRequest: { req in
                try req.content.encode(newPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
               
                let decoded = try resp.content.decode(Planet.self)
               
                XCTAssertEqual(decoded.name, "Mars")
                XCTAssertEqual(decoded.id, newPlanetId)
                XCTAssertEqual(decoded.$galaxy.id, newGalaxyId)

               
                let newPlanets = try app.db.query(Planet.self).all().wait()
               
                XCTAssertEqual(newPlanets.count, 2)
                XCTAssert(newPlanets.contains { $0.name == "Mars" })
               
                let newMars = newPlanets.first { $0.name == "Mars" }
               
                XCTAssertEqual(newMars?.id, newPlanetId)
            }

            let newGalaxy = Galaxy(id: newGalaxyId, name: "Andromeda")
            
            try app.testable().test(.POST, "/planet/\(ChildSeeding.earthId)/galaxy", beforeRequest: { req in
                try req.content.encode(newGalaxy)
            }) { (resp) in
                XCTAssertEqual(resp.status, .notFound)
            }
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
        let newGalaxyId = UUID()
        
        do {
            let newPlanetId = UUID()
            let newPlanet = Planet(id: newPlanetId, name: "Mars", galaxyID: newGalaxyId)
            
            try app.testable().test(.POST, "/planet", beforeRequest: { req in
                try req.content.encode(newPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Mars")
                XCTAssertEqual(decoded.id, newPlanetId)
                XCTAssertEqual(decoded.$galaxy.id, newGalaxyId)

                let newPlanets = try app.db.query(Planet.self).all().wait()
                
                XCTAssertEqual(newPlanets.count, 2)
                XCTAssert(newPlanets.contains { $0.name == "Mars" })
                
                let newMars = newPlanets.first { $0.name == "Mars" }
                
                XCTAssertEqual(newMars?.id, newPlanetId)
            }

            let newTagId = UUID()
            let newTag = Tag(id: newTagId, name: "Red")
            
            try app.testable().test(.POST, "/tag", beforeRequest: { req in
                try req.content.encode(newTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Red")
                XCTAssertEqual(decoded.id, newTagId)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 2)
                XCTAssert(newTags.contains { $0.name == "Red" })
                
                let newMarsTag = newTags.first { $0.name == "Red" }
                
                XCTAssertEqual(newMarsTag?.id, newTagId)
            }

            let otherTagId = UUID()
            let otherNewTag = Tag(id: otherTagId, name: "Uninhabitable")
            
            try app.testable().test(.POST, "/planet/\(newPlanetId)/tag", beforeRequest: { req in
                try req.content.encode(otherNewTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, "Uninhabitable")
                XCTAssertEqual(decoded.id, otherTagId)
                
                let newTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(newTags.count, 2)
                XCTAssert(newTags.contains { $0.name == "Red" })
                
                let newMarsTag = newTags.first { $0.name == "Red" }
                
                XCTAssertEqual(newMarsTag?.id, newTagId)
            }

            let otherPlanetId = UUID()
            let otherNewPlanet = Planet(id: otherPlanetId, name: "Venus", galaxyID: newGalaxyId)
            
            try app.testable().test(.POST, "/tag/\(newTagId)/planet", beforeRequest: { req in
                try req.content.encode(otherNewPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, "Venus")
                XCTAssertEqual(decoded.id, otherPlanetId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    private func configure(_ app: Application) throws {
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

