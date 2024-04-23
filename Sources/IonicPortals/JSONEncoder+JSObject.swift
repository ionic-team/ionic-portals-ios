//
//  JSValueEncoder.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/3/22.
//

import Foundation
import Capacitor
import Combine


public extension JSONEncoder {
    @available(*, deprecated, renamed: "encodeJsObject")
    func encodeJSObject<T: Encodable>(_ value: T) throws -> JSValue {
        try encodeJsObject(value)
    }

    @available(*, deprecated, message: "Use JSValueEncoder from Capacitor. This will be removed in the next release.")
    func encodeJsObject<T: Encodable>(_ value: T) throws -> JSObject {
        let data = try encode(value)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary

        // Any valid Codable type that is keyed should not fail here.
        // An unkeyed or single value container would have failed in the
        // JSONSerialization step.
        return JSTypes.coerceDictionaryToJSObject(dictionary)!
    }
}
