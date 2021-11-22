import XCTest
@testable import CrudRouter
import Vapor
import XCTVapor

final class CrudChildrenRouteCreationTests: XCTestCase {
    func testChildrenCrudRegistrationWithDefaultRoute() throws {
        let app = Application()
        app.crud(register: Galaxy.self) { router in
            router.crud(children: \.$planets)
        }

        XCTAssert(app.routes.all.count == 10)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["POST", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["PUT", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID"] })

        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "galaxy", ":galaxiesID", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
    }

    func testChildrenCrudRegistrationWithMethodsSelected() throws {
        let app = Application()
        app.crud(register: Galaxy.self) { router in
            router.crud(children: \.$planets, .only([.delete, .readAll]))
        }

        XCTAssert(app.routes.all.count == 7)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["POST", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["PUT", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID"] })

        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID", "planet"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
    }

    func testChildrenCrudRegistrationWithMethodsExcluded() throws {
        let app = Application()
        app.crud(register: Galaxy.self) { router in
            router.crud(children: \.$planets, .except([.readAll, .update]))
        }

        XCTAssert(app.routes.all.count == 8)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["POST", "galaxy"] })
        XCTAssert(paths.contains { $0 == ["PUT", "galaxy", ":galaxiesID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID"] })

        XCTAssert(paths.contains { $0 == ["GET", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "galaxy", ":galaxiesID", "planet"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "galaxy", ":galaxiesID", "planet", ":planetsID"] })
    }
}
