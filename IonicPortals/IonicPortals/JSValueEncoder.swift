//
//  JSValueEncoder.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/4/22.
//

import Foundation
import Capacitor
import Combine

public struct JSValueEncoder: TopLevelEncoder {
    public init() {}
    public func encode<T>(_ value: T) throws -> JSValue where T : Encodable {
        let encoder = _JSValueEncoder()
        try value.encode(to: encoder)
        return encoder.jsValueContainer.data
    }
}

protocol JSValueContainer {
    var data: JSValue { get }
}

class _JSValueEncoder: Encoder {
    var codingPath: [CodingKey] = []
    
    var jsValueContainer: JSValueContainer!
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = KeyedContainer<Key>()
        jsValueContainer = container
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = UnkeyedContainer()
        jsValueContainer = container
        return container
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = SingleValueContainer()
        jsValueContainer = container
        return container
    }
}

class _JSValueReferencingEncoder: _JSValueEncoder {
    
}

extension _JSValueEncoder {
    class KeyedContainer<Key: CodingKey>: JSValueContainer {
        var data: JSValue {
            containerStorage.reduce(into: JSObject()) { partialResult, keyContainer in
                let (key, container) = keyContainer
                partialResult[key] = container.data
            }
        }
        
        private var containerStorage: [String: JSValueContainer] = [:]
        var codingPath: [CodingKey] = []
    }
}


extension _JSValueEncoder.KeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        var container = nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }
    
    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = _JSValueEncoder.SingleValueContainer()
        containerStorage[key.stringValue] = container
        return container
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let container = _JSValueEncoder.KeyedContainer<NestedKey>()
        containerStorage[key.stringValue] = container
        
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _JSValueEncoder.UnkeyedContainer()
        containerStorage[key.stringValue] = container
        
        return container
    }
    
    func superEncoder() -> Encoder {
        fatalError()
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        fatalError()
    }
    
    
}

extension _JSValueEncoder {
    class SingleValueContainer: SingleValueEncodingContainer, JSValueContainer {
        var codingPath: [CodingKey] = []
        var data: JSValue { _data }
        var _data: JSValue!
        
        func encodeNil() throws {
            _data = NSNull()
        }
        
        func encode(_ value: Bool) throws {
            _data = value
        }
        
        func encode(_ value: String) throws {
            _data = value
        }
        
        func encode(_ value: Double) throws {
            _data = value
        }
        
        func encode(_ value: Float) throws {
            _data = value
        }
        
        func encode(_ value: Int) throws {
            _data = value
        }
        
        func encode(_ value: Int8) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: Int16) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: Int32) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: Int64) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: UInt) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: UInt8) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: UInt16) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: UInt32) throws {
            _data = value as NSNumber
        }
        
        func encode(_ value: UInt64) throws {
            _data = value as NSNumber
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
            let encoder = _JSValueEncoder()
            try value.encode(to: encoder)
            _data = encoder.jsValueContainer.data
        }
        
        
    }
}

extension _JSValueEncoder {
    class UnkeyedContainer: UnkeyedEncodingContainer, JSValueContainer {
        var codingPath: [CodingKey] = []
        
        var data: JSValue {
            storage.map { $0.data }
        }
        
        var storage: [JSValueContainer] = []
        
        var count: Int { storage.count }
        
        func encodeNil() throws {
            var container = nestedSingleValueContainer()
            try container.encodeNil()
        }
        
        func encode<T>(_ value: T) throws where T: Encodable {
            var container = nestedSingleValueContainer()
            try container.encode(value)
        }
        
        private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
            let container = _JSValueEncoder.SingleValueContainer()
            storage.append(container)
            
            return container
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            let container = _JSValueEncoder.KeyedContainer<NestedKey>()
            storage.append(container)
            
            return KeyedEncodingContainer(container)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            let container = _JSValueEncoder.UnkeyedContainer()
            storage.append(container)
            
            return container
        }
        
        func superEncoder() -> Encoder {
            fatalError()
        }
    }
}
