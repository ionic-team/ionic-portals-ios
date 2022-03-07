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
    struct JSObjectEncodingError<T: Encodable>: LocalizedError {
        let errorDescription = "Encoding failed when coercing the Dictionary representation of \(T.self) to JSObject"
    }
    
    func encodeJSObject<T: Encodable>(_ value: T) throws -> JSValue {
        let data = try encode(value)
        
        let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
       
        // Any valid Codable type should not fail here. 
        return JSTypes.coerceDictionaryToJSObject(dictionary)!
    }
}
