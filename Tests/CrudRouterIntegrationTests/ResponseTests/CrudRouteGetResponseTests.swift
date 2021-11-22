import FluentSQLiteDriver
import Fluent
import XCTVapor

final class CrudRouteGetResponseTests: XCTestCase {
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
    
    func testGetBase() throws {
        app.crud(register: Galaxy.self)
        
        do {
            try app.testable().test(.GET, "/galaxy") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Galaxy].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Milky Way")
                XCTAssert(decoded[0].id == BaseGalaxySeeding.milkyWayId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testGetChildren() throws {
        app.crud(register: Galaxy.self) { (controller) in
            controller.crud(children: \.$planets)
        }
        
        do {
            try app.testable().test(.GET, "/galaxy") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Galaxy].self)
                let allGalaxies = try app.db.query(Galaxy.self).all().wait()
                print(allGalaxies)
                print()
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Milky Way")
                XCTAssert(decoded[0].id == BaseGalaxySeeding.milkyWayId)
            }
            
            try app.testable().test(.GET, "/galaxy/\(BaseGalaxySeeding.milkyWayId)/planet") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Planet].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == ChildSeeding.earthId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testGetParents() throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(parent: \.$galaxy)
        }
        
        do {
            try app.testable().test(.GET, "/planet") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Planet].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == ChildSeeding.earthId)
            }
            
            try app.testable().test(.GET, "/planet/\(ChildSeeding.earthId)/galaxy") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode(Galaxy.self)
                
                XCTAssert(decoded.name == "Milky Way")
                XCTAssert(decoded.id == BaseGalaxySeeding.milkyWayId)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }
    
    func testGetSiblings() async throws {
        app.crud(register: Planet.self) { (controller) in
            controller.crud(siblings: \.$tags)
        }
        
        app.crud(register: Tag.self) { controller in
            controller.crud(siblings: \.$planets)
        }
        
        do {
            try app.testable().test(.GET, "/planet") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Planet].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == ChildSeeding.earthId)
            }
            
            try app.testable().test(.GET, "/tag") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Tag].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == SiblingSeeding.lifeSupportingId)
            }
            
            try app.testable().test(.GET, "/planet/\(ChildSeeding.earthId)/tag") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Tag].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Life-Supporting")
                XCTAssert(decoded[0].id == SiblingSeeding.lifeSupportingId)
            }
            
            try app.testable().test(.GET, "/tag/\(SiblingSeeding.lifeSupportingId)/planet") { (resp) in
                XCTAssert(resp.status == .ok)
                
                let decoded = try resp.content.decode([Planet].self)
                
                XCTAssert(decoded.count == 1)
                XCTAssert(decoded[0].name == "Earth")
                XCTAssert(decoded[0].id == ChildSeeding.earthId)
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
        ("testPublicable", testGetBase),
    ]
}
