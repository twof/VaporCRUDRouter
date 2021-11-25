import XCTest
import XCTVapor
@testable import CrudRouter
import Vapor

class HighRecursiveDepthTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let app = Application()
        app.crud(register: Galaxy.self) { router in
            router.crud(children: \.$planets) { childRouter in
                childRouter.crud(siblings: \Planet.$tags)
            }
        }

        app.crud(register: Planet.self) { (router: CrudController<Planet>) in
            router.crud(parent: \Planet.$galaxy) { (parentRouter: CrudParentController<CrudController<Planet>.OriginType, Galaxy>) in
//                parentRouter.crud(children: \Galaxy.$planets)
            }
        }
    }
}
