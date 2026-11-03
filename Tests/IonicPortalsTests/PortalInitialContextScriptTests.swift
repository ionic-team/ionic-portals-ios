import XCTest
@testable import IonicPortals
import Capacitor

final class PortalInitialContextScriptTests: XCTestCase {
    private func decodedContext(for portal: Portal, file: StaticString = #filePath, line: UInt = #line) throws -> [String: Any] {
        let prefix = "window.portalInitialContext = "
        let script = portal.initialContextScript
        XCTAssertTrue(script.hasPrefix(prefix), file: file, line: line)
        let json = Data(script.dropFirst(prefix.count).utf8)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any], file: file, line: line)
    }

    func test_initialContextScript__when_context_contains_a_date__it_is_serialized_as_a_string() throws {
        let portal = Portal(name: "test", initialContext: ["date": Date(timeIntervalSince1970: 0)])

        let context = try decodedContext(for: portal)
        let value = try XCTUnwrap(context["value"] as? [String: Any])
        XCTAssertTrue((value["date"] as? String)?.hasPrefix("1970-01-01") == true)
    }

    func test_initialContextScript__when_context_is_not_valid_json__only_the_escaped_name_is_provided() throws {
        let name = #"my "portal""#
        let portal = Portal(name: name, initialContext: ["number": Double.nan])

        let context = try decodedContext(for: portal)
        XCTAssertEqual(context["name"] as? String, name)
        XCTAssertNil(context["value"])
    }
}
