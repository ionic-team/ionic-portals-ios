//
//  IONPortalsPubSubCoersionTests.swift
//  IonicPortalsTests
//
//  Created by Steven Sherry on 5/14/22.
//

import XCTest
@testable import IonicPortals

class IONPortalsPubSubCoersionTests: XCTestCase {
    func test_coerceToJsValue__when_provided_valid_json_objective_c_types__it_does_not_return_nil() {
        let string: NSString = "hello"
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(string))
        
        let date = NSDate()
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(date))
        
        let null = NSNull()
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(null))
        
        let array: NSArray = ["a", 1, 2.5]
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(array))
        
        let number: NSNumber = 10.5
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(number))
        
        let dict: NSDictionary = ["hello": 1, "goodbye": "string"]
        XCTAssertNotNil(IONPortalsPubSub.coerceToJsValue(dict))
    }
    
    func test_coerceToJsValue__when_provided_objective_c_types_not_expressible_in_json__it_returns_nil() {
        let predicate = NSPredicate { _, _ in true }
        XCTAssertNil(IONPortalsPubSub.coerceToJsValue(predicate))
        
        let url = NSURL()
        XCTAssertNil(IONPortalsPubSub.coerceToJsValue(url))
        
        let calendar = NSCalendar.current
        XCTAssertNil(IONPortalsPubSub.coerceToJsValue(calendar))
    }
}
