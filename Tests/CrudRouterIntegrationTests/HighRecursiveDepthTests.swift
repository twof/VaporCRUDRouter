import XCTest
@testable import CrudRouter
import Vapor

class HighRecursiveDepthTests: XCTestCase {
    func testExample() throws {
        let app = Application()

        app.crud(register: Galaxy.self) { router in
            router.crud(children: \.$planets) { childRouter in
                childRouter.crud(siblings: \.$tags) { tagRouter in
                    tagRouter.crud(siblings: \.$planets) { childRouter in
                        childRouter.crud(siblings: \.$tags) { tagRouter in
                            tagRouter.crud(siblings: \.$planets) { planetRouter in
                                planetRouter.crud(parent: \.$galaxy)
                            }
                        }
                    }
                }
            }
        }
    }
}
