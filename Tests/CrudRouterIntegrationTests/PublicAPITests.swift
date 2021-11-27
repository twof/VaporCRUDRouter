import XCTest
import CrudRouter
import Vapor

class PublicAPITest: XCTestCase {
    func testExample() throws {
        let app = Application()
        app.crud("foo", register: Planet.self, .only([.delete])) { router in
            router.crud(at: "foo", siblings: \.$tags, .only([]))
            router.crud(at: "foo", parent: \.$galaxy, .only([]))
        }

        app.crud("foo", register: Galaxy.self, .only([.delete])) { router in
            router.crud(at: "foo", children: \.$planets, .only([]))
        }
    }
}
