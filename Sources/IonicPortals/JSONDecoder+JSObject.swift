//
//  JSONDecoder+JSObject.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/3/22.
//

import Capacitor
import Foundation

public extension JSONDecoder {
    // These docs aren't really discoverable at the moment unfortunately
    // swiftlint:disable:next missing_docs
    func decodeJSObject<T: Decodable>(_ type: T.Type, from object: JSObject) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        let result = try decode(T.self, from: data)
        return result
    }
}
