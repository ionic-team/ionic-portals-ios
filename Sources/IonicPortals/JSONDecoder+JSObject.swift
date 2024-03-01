//
//  JSONDecoder+JSObject.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/3/22.
//

import Foundation
import Capacitor

public extension JSONDecoder {
    @available(*, deprecated, renamed: "decodeJsObject")
    func decodeJSObject<T: Decodable>(_ type: T.Type, from object: JSObject) throws -> T {
        try decodeJsObject(type, from: object)
    }

    @available(*, deprecated, message: "Use JSValueDecoder from Capacitor. This will be removed in the next release.")
    func decodeJsObject<T: Decodable>(_ type: T.Type, from object: JSObject) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return try decode(T.self, from: data)
    }
}

