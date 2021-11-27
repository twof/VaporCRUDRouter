import FluentSQLiteDriver
import Fluent
import XCTVapor

final class CrudRouteDeleteResponseTests: XCTestCase {
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

    func testDeleteBase() throws {
        app.crud(register: Galaxy.self, .only([.delete]))

        do {
            let allGalaxies = try app.db.query(Galaxy.self).all().wait()

            XCTAssertEqual(allGalaxies.count, 1)
            try app.testable().test(.DELETE, "/galaxy/\(BaseGalaxySeeding.milkyWayId)") { (resp) in
                XCTAssert(resp.status == .noContent)

                let allGalaxies = try app.db.query(Galaxy.self).all().wait()

                XCTAssertEqual(allGalaxies.count, 0)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }

    func testDeleteChild() throws {
        app.crud(register: Galaxy.self, .only([])) { (controller) in
            controller.crud(children: \.$planets, .only([.delete]))
        }

        do {
            let galaxy = try Galaxy.find(BaseGalaxySeeding.milkyWayId, on: app.db).wait()
            let children = try galaxy!.$planets.get(on: app.db).wait()

            XCTAssertEqual(children.count, 1)

            try app.testable().test(.DELETE, "/galaxy/\(BaseGalaxySeeding.milkyWayId)/planet/\(ChildSeeding.earthId)") { (resp) in
                XCTAssert(resp.status == .noContent)

                let galaxy = try Galaxy.find(BaseGalaxySeeding.milkyWayId, on: app.db).wait()
                let children = try galaxy!.$planets.get(on: app.db).wait()

                XCTAssertEqual(children.count, 0)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }

    func testDeleteSiblingTags() async throws {
        app.crud(register: Planet.self, .only([])) { controller in
            controller.crud(siblings: \.$tags, .only([.delete]))
        }

        do {
            let planet = try Planet.find(ChildSeeding.earthId, on: app.db).wait()
            let tagSiblings = try planet!.$tags.get(on: app.db).wait()

            XCTAssertEqual(tagSiblings.count, 1)

            try app.testable().test(.DELETE, "/planet/\(ChildSeeding.earthId)/tag/\(SiblingSeeding.lifeSupportingId)") { (resp) in
                XCTAssertEqual(resp.status, .noContent)

                let planet = try Planet.find(ChildSeeding.earthId, on: app.db).wait()
                let tagSiblings = try planet!.$tags.get(on: app.db).wait()

                XCTAssertEqual(tagSiblings.count, 0)
            }
        } catch {
            XCTFail("Probably couldn't decode to public galaxy: \(error.localizedDescription)")
        }
    }

    func testDeleteSiblingPlanets() async throws {
        app.crud(register: Tag.self, .only([])) { controller in
            controller.crud(siblings: \.$planets, .only([.delete]))
        }

        do {
            let tag = try Tag.find(SiblingSeeding.lifeSupportingId, on: app.db).wait()
            let planetSiblings = try tag!.$planets.get(on: app.db).wait()

            XCTAssertEqual(planetSiblings.count, 1)

            try app.testable().test(.DELETE, "/tag/\(SiblingSeeding.lifeSupportingId)/planet/\(ChildSeeding.earthId)") { (resp) in
                XCTAssertEqual(resp.status, .noContent)

                let tag = try Tag.find(SiblingSeeding.lifeSupportingId, on: app.db).wait()
                let planetSiblings = try tag!.$planets.get(on: app.db).wait()

                XCTAssertEqual(planetSiblings.count, 0)
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
}
