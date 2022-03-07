//
//  JSObjectEncodingDecodingTests.swift
//  IonicPortalsTests
//
//  Created by Steven Sherry on 3/3/22.
//

import XCTest
import IonicPortals
import Capacitor

class JSObjectEncodingDecodingTests: XCTestCase {
    struct MagicTheGatheringCard: Codable {
        var name: String
        var manaCost: String
        var convertedManaCost: Int8
        var maybeNil: String?
        var isAThing: Bool
    }
    
    let card = MagicTheGatheringCard(
        name: "Counterspell",
        manaCost: "{U}{U}",
        convertedManaCost: 2,
        maybeNil: nil,
        isAThing: true
    )
    
    func test_encode__when_given_a_valid_codable_object__encoding_succeeds() throws {
        let encoder = JSValueEncoder()
        let object = try encoder.encode(card)
        
        guard let object = object as? JSObject else {
            XCTFail("card should have been encodable as JSObject")
            return
        }
        
        
//        let encoder = JSONEncoder()
//        let object = try encoder.encodeJSObject(card)
//
        XCTAssertNotNil(object["name"])
        XCTAssertEqual(card.name, object["name"] as? String)
//
        XCTAssertNotNil(object["manaCost"])
        XCTAssertEqual(card.manaCost, object["manaCost"] as? String)
//
        dump(object)
//
        XCTAssertNotNil(object["convertedManaCost"] as? NSNumber)
        XCTAssertEqual(card.convertedManaCost as NSNumber, object["convertedManaCost"] as? NSNumber)
//
        XCTAssertNil(object["maybeNil"])
    }
    
    func testJSObjectEncodingThrowsAJSObjectEncodingErrorWhenProvidedATypeNotRepresentableAsAJSObject() throws {
//        let object: JSObject = [
//            "bar": Foo.Bar.bazz
//        ]
//        struct Foo {
//            enum Bar {
//                case bazz
//            }
//            
//            var bar = Bar.bazz
//        }
//        
//        let encoder = JSONEncoder()
//        do {
//            _ = try encoder.encodeJSObject(Foo())
//        } catch let error as JSONEncoder.JSObjectEncodingError<Int> {
//            XCTAssertEqual(error.localizedDescription, "Encoding failed when coercing the Dictionary representation of Int to JSObject")
//        }
    }
    
    func testJSObjectDecodingSucceeds() throws {
        let jsObject: JSObject = [
            "name": "Counterspell",
            "manaCost": "{U}{U}",
            "convertedManaCost": NSNumber(value: UInt(2)),
            "isAThing": NSNumber(value: false),
            "maybeNil": NSNull()
        ]
        
        dump(jsObject)
        
        let decoder = JSONDecoder()
        
        let card = try decoder.decodeJSObject(MagicTheGatheringCard.self, from: jsObject)
        
        XCTAssertEqual(card.name, jsObject["name"] as? String)
        XCTAssertEqual(card.manaCost, jsObject["manaCost"] as? String)
        XCTAssertEqual(card.convertedManaCost, 2) //jsObject["convertedManaCost"] as? UInt)
    }
    
    func testJSObjectDecodingFails() throws {
//        let encoder = JSONEncoder()
//        let value = try encoder.encodeJSObject(1)
//        print(value)
    }
    
    func testEncodingPerformance() {
        measure {
            let encoder = JSValueEncoder()
            let _ = try! encoder.encode(card)
        }
    }
    
    func testDancingPerformance() {
        measure {
            let jsonEncoder = JSONEncoder()
            let _ = try! jsonEncoder.encodeJSObject(card)
        }
    }
    
}
