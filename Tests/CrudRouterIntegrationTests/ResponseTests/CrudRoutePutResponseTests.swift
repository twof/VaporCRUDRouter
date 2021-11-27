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
        app.crud(register: Planet.self, .only([])) { (controller) in
            controller.crud(siblings: \.$tags, .only([.update]))
        }
        
        app.crud(register: Tag.self, .only([])) { controller in
            controller.crud(siblings: \.$planets, .only([.update]))
        }
        
        do {
            let planetId = ChildSeeding.earthId
            let galaxyId = BaseGalaxySeeding.milkyWayId
            let existingPlanet = Planet(id: planetId, name: "Earth 2", galaxyID: galaxyId)

            let tagId = SiblingSeeding.lifeSupportingId
            let existingTag = Tag(id: tagId, name: "Kind of Life Supporting")
            
            try app.testable().test(.PUT, "/planet/\(planetId)/tag/\(tagId)", beforeRequest: { req in
                try req.content.encode(existingTag)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)

                let decoded = try resp.content.decode(Tag.self)
                
                XCTAssertEqual(decoded.name, existingTag.name)
                XCTAssertEqual(decoded.id, tagId)
                
                let allTags = try app.db.query(Tag.self).all().wait()
                
                XCTAssertEqual(allTags.count, 1)
                XCTAssert(allTags.contains { $0.name == existingTag.name })

                let earth = try Planet.find(planetId, on: app.db).wait()
                let tags = try earth?.$tags.get(on: app.db).wait()
                let tagsContainsUpdatedTag = tags?.contains { $0.name == existingTag.name }
                
                XCTAssertEqual(tagsContainsUpdatedTag, true)
            }
            
            try app.testable().test(.PUT, "/tag/\(tagId)/planet/\(planetId)", beforeRequest: { req in
                try req.content.encode(existingPlanet)
            }) { (resp) in
                XCTAssertEqual(resp.status, .ok)
                
                let decoded = try resp.content.decode(Planet.self)
                
                XCTAssertEqual(decoded.name, existingPlanet.name)
                XCTAssertEqual(decoded.id, planetId)

                let allPlanets = try app.db.query(Planet.self).all().wait()

                XCTAssertEqual(allPlanets.count, 1)
                XCTAssert(allPlanets.contains { $0.name == existingPlanet.name })

                let parentTag = try Tag.find(tagId, on: app.db).wait()
                let planets = try parentTag?.$planets.get(on: app.db).wait()
                let tagsContainsUpdatedTag = planets?.contains { $0.name == existingPlanet.name }

                XCTAssertEqual(tagsContainsUpdatedTag, true)
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
        ("testPublicable", testPutBase),
    ]
}

