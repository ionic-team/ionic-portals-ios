//
//  JSValueDecoder.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/4/22.
//

import Foundation
import Capacitor
import Combine

class _JSValueDecoder: Decoder {
    var codingPath: [CodingKey] = []
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        fatalError()
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        fatalError()
    }
}

extension _JSValueDecoder {
    class KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var codingPath: [CodingKey] = []
        
        var allKeys: [Key] = []
        
        func contains(_ key: Key) -> Bool {
            fatalError()
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            fatalError()
        }
        
        
        
//        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
//
//        }
//
//        func decode(_ type: String.Type, forKey key: Key) throws -> String {
//
//        }
//
//        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
//
//        }
//
//        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
//
//        }
//
//        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
//
//        }
//
//        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
//
//        }
//
//        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
//
//        }
//
//        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
//
//        }
//
//        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
//
//        }
//
//        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
//
//        }
//
//        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
//
//        }
//
//        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
//
//        }
//
//        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
//
//        }
//
//        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
//
//        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            fatalError()
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            fatalError()
        }
        
        func superDecoder() throws -> Decoder {
            fatalError()
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            fatalError()
        }
        
        
    }
}

