import XCTest
@testable import CrudRouter

final class CrudRouterTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CrudRouter().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
