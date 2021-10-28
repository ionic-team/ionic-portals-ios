import XCTest
@testable import Cordova

final class CordovaTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Cordova().text, "Hello, World!")
    }
}
