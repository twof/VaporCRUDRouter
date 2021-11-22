import XCTest
@testable import CrudRouter
import Vapor
import XCTVapor

final class CrudParentRouteCreationTests: XCTestCase {
    func testCrudRegistrationWithDefaultRoute() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(parent: \.$galaxy)
        }

        XCTAssert(app.routes.all.count == 7)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID", "galaxy"] })
    }

    func testChildrenCrudRegistrationWithMethodsSelected() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(parent: \.$galaxy, .only([.read]))
        }

        XCTAssert(app.routes.all.count == 6)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID", "galaxy"] })
    }

    func testChildrenCrudRegistrationWithMethodsExcluded() throws {
        let app = Application()
        app.crud(register: Planet.self) { router in
            router.crud(parent: \.$galaxy, .except([.read]))
        }

        XCTAssert(app.routes.all.count == 6)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })

        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID", "galaxy"] })
    }
}
