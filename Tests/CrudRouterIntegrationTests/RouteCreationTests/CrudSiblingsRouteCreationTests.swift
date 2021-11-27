import XCTest
@testable import CrudRouter
import Vapor
import XCTVapor

final class CrudSiblingsRouteCreationTests: XCTestCase {
    func testRegistrationWithDefaultRoute() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(siblings: \.$tags)
        }

        XCTAssert(app.routes.all.count == 10)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "tag"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet", ":planetsID", "tag"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID", "tag", ":tagsID"] })
    }

    func testRegistrationWithDefaultRouteInverted() throws {
        let app = Application()
        app.crud(register: Tag.self) { router in
            router.crud(siblings: \.$planets)
        }

        XCTAssert(app.routes.all.count == 10)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "tag"] })
        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "tag"] })
        XCTAssert(paths.contains { $0 == ["PUT", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "tag", ":tagsID", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "tag", ":tagsID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID", "planet", ":planetsID"] })
    }

    func testRegistrationWithMethodsSelected() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(siblings: \.$tags, .only([.delete, .readAll]))
        }

        XCTAssert(app.routes.all.count == 7)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "tag"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID", "tag", ":tagsID"] })
    }

    func testRegistrationWithMethodsSelectedInverted() throws {
        let app = Application()
        app.crud(register: Tag.self) { router in
            router.crud(siblings: \.$planets, .only([.delete, .readAll]))
        }

        XCTAssert(app.routes.all.count == 7)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "tag"] })
        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "tag"] })
        XCTAssert(paths.contains { $0 == ["PUT", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID", "planet"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID", "planet", ":planetsID"] })
    }

    func testRegistrationWithMethodsExcluded() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(siblings: \.$tags, .except([.readAll, .update]))
        }

        XCTAssert(app.routes.all.count == 8)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet", ":planetsID", "tag"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID", "tag", ":tagsID"] })
    }

    func testRegistrationWithMethodsExcludedInverted() throws {
        let app = Application()
        app.crud(register: Tag.self) { router in
            router.crud(siblings: \.$planets, .except([.readAll, .update]))
        }

        XCTAssert(app.routes.all.count == 8)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "tag"] })
        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "tag"] })
        XCTAssert(paths.contains { $0 == ["PUT", "tag", ":tagsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "tag", ":tagsID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "tag", ":tagsID", "planet"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "tag", ":tagsID", "planet", ":planetsID"] })
    }
}
