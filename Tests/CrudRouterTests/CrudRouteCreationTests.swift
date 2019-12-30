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

//func routes(_ router: RoutesBuilder) throws {
//    router.crud(register: Galaxy.self) { controller in
//        controller.crud(children: \.$planets)
//    }
//    router.crud(register: Planet.self) { controller in
//        controller.crud(parent: \.$galaxy)
//        controller.crud(siblings: \.$tags)
//    }
//    router.crud(register: Tag.self) { controller in
//        controller.crud(siblings: \.$planets)
//    }
//}

final class CrudRouteCreationTests: XCTestCase {
    func testBaseCrudRegistrationWithRouteName() throws {
        let app = Application()
        app.crud("planets", register: Planet.self)

        XCTAssert(app.routes.all.isEmpty == false)
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

        XCTAssert(app.routes.all.isEmpty == false)
        XCTAssert(app.routes.all.count == 5)
        let paths = app.routes.all.map { [$0.method.rawValue] + $0.path.map { $0.stringComponent } }

        XCTAssert(paths.contains { $0 == ["GET", "planet"] })
        XCTAssert(paths.contains { $0 == ["GET", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["POST", "planet"] })
        XCTAssert(paths.contains { $0 == ["PUT", "planet", ":planetsID"] })
        XCTAssert(paths.contains { $0 == ["DELETE", "planet", ":planetsID"] })
    }

    static var allTests = [
        ("testBaseCrudRegistrationWithRouteName", testBaseCrudRegistrationWithRouteName),
        ("testBaseCrudRegistrationWithDefaultRoute", testBaseCrudRegistrationWithDefaultRoute),
    ]
}
