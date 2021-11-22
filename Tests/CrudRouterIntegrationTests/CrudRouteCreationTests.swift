import XCTest
@testable import CrudRouter
import Vapor
import XCTVapor

extension PathComponent {
    var stringComponent: String {
        switch self {
        case .constant(let val):
            return val
        case .parameter(let val):
            return ":\(val)"
        default:
            return "all"
        }
    }
}

final class CrudRouteCreationTests: XCTestCase {
    func testBaseCrudRegistrationWithRouteName() throws {
        let app = Application()
        app.crud("planets", register: Planet.self)

        XCTAssert(app.routes.all.count == 5)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planets"] })
        XCTAssert(paths.contains { $0 == ["GET", "planets", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planets"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planets", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planets", ":planetsID"] })
    }

    func testBaseCrudRegistrationWithDefaultRoute() throws {
        let app = Application()
        app.crud(register: Planet.self)

        XCTAssert(app.routes.all.count == 5)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })
    }

    func testBaseCrudRegistrationWithMethodsSelected() throws {
        let app = Application()
        app.crud(register: Planet.self, .only([.create, .delete]))

        XCTAssert(app.routes.all.count == 2)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })
    }

    func testBaseCrudRegistrationWithMethodsExcluded() throws {
        let app = Application()
        app.crud(register: Planet.self, .except([.delete]))

        XCTAssert(app.routes.all.count == 4)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
    }

    static var allTests = [
        ("testBaseCrudRegistrationWithRouteName", testBaseCrudRegistrationWithRouteName),
        ("testBaseCrudRegistrationWithDefaultRoute", testBaseCrudRegistrationWithDefaultRoute),
    ]
}
