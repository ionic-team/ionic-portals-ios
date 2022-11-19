//
//  JSValueEncoder.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/3/22.
//

import Capacitor
import Foundation

public extension JSONEncoder {
    func encodeJSObject<T: Encodable>(_ value: T) throws -> JSValue {
        let data = try encode(value)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
       
        // Any valid Codable type should not fail here. 
        return JSTypes.coerceDictionaryToJSObject(dictionary)!
    }
}
