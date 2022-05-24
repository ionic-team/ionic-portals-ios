//
//  JSONDecoder+JSObject.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/3/22.
//

import Foundation
import Capacitor

public extension JSONDecoder {
    func decodeJSObject<T: Decodable>(_ type: T.Type, from object: JSObject) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        let result = try decode(T.self, from: data)
        return result
    }
}

