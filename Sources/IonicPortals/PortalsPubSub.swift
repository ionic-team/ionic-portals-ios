//
//  PortalsPubSub.swift
//  IonicPortals
//
//  Created by Steven Sherry on 5/12/22.
//

import Foundation
import Combine
import Capacitor

// An interface that enables marshalling data to and from a ``Portal`` over an event bus
public class PortalsPubSub {
    private var publishers = ConcurrentDictionary<String, PassthroughSubject<SubscriptionResult, Never>>(label: "io.ionic.portals.subjects")
    
    public init() {}

    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: An `AnyCancellable` that unsubscribes from the topic when deallocated.
    public func subscribe(to topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> AnyCancellable {
        let publisher = subject(for: topic)
        let cancellable = publisher.sink(receiveValue: callback)
        return cancellable
    }
    
    internal func subject(for topic: String) -> PassthroughSubject<SubscriptionResult, Never> {
        let publisher: PassthroughSubject<SubscriptionResult, Never>
        if let existing = publishers[topic] {
            publisher = existing
        } else {
            publisher = PassthroughSubject<SubscriptionResult, Never>()
            publishers[topic] = publisher
        }
        
        return publisher
    }
    
    /// Publish event to all listeners of a topic
    /// - Parameters:
    ///   - message: The data to deliver to all subscribers. Must be a valid JSON data type. Defaults to nil.
    ///   - topic: The topic to publish to
    public func publish(_ message: JSValue? = nil, to topic: String) {
        publishers[topic]?.send(SubscriptionResult(topic: topic, data: message))
    }
    
    /// Shared PubSub instance to publish events globally amongst subscribers
    public static let shared = PortalsPubSub()
    
    /// Subscribe to a topic and execute the provided callback when the event is received. Uses ``shared`` to subscribe.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: An `AnyCancellable` that unsubscribes from the topic when deallocated.
    public static func subscribe(to topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> AnyCancellable {
        shared.subscribe(to: topic, callback)
    }
    
    /// Publish event to all listeners of a topic. Uses ``shared`` to publish.
    /// - Parameters:
    ///   - message: The data to deliver to all subscribers. Must be a valid JSON data type. Defaults to nil.
    ///   - topic: The topic to publish to
    public static func publish(_ message: JSValue? = nil, to topic: String) {
        shared.publish(message, to: topic)
    }
}

class ConcurrentDictionary<Key: Hashable, Value> {
    private var _dict: Dictionary<Key, Value>
    var dict: Dictionary<Key, Value> {
        queue.sync { _dict }
    }
    private let queue: DispatchQueue
    
    init(label: String, dict: [Key: Value] = [:]) {
        queue = DispatchQueue(label: label, qos: .userInitiated, attributes: .concurrent)
        self._dict = dict
    }
    
    subscript(_ key: Key) -> Value? {
        get { queue.sync { _dict[key] } }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._dict[key] = newValue
            }
        }
    }
}

extension ConcurrentDictionary: Collection {
    var startIndex: Dictionary<Key, Value>.Index { dict.startIndex }
    var endIndex: Dictionary<Key, Value>.Index { dict.endIndex }
    func index(after i: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Index {
        dict.index(after: i)
    }
    
    subscript(position: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Element {
        get {
            dict[position]
        }
    }
}

/// The data emitted to a subscriber
public struct SubscriptionResult {
    /// The topic the ``SubscriptionResult`` was emitted on
    public var topic: String
    /// The value emitted
    public var data: JSValue?
    
    var dictionaryRepresentation: [String: JSValue?] {
        return [
            "topic": topic,
            "data": data
        ]
    }
}

/// An Objective-C interface that enables marshalling data to and from a ``Portal`` over an event bus. If using Swift, ``PortalsPubSub`` is the perferred interface.
@objc public class IONPortalsPubSub: NSObject {
    class Cancellable: NSObject {
        var cancellable: AnyCancellable
        init(_ cancellable: AnyCancellable) {
            self.cancellable = cancellable
        }
    }
    
    
    private override init() { }
    
    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: A subscription reference to use for unsubscribing
    /// > Tip: You must retain a reference to the returned to keep the subscription alive. To unsubscribe, set the the reference to nil.
    @objc(subscribeToTopic:callback:) public static func subscribe(topic: String, callback: @escaping ([String: Any]) -> Void) -> Any {
        let cancellable = PortalsPubSub.subscribe(to: topic) { result in
            callback(result.dictionaryRepresentation as [String: Any])
        }
        
        return Cancellable(cancellable)
    }
        
    /// Publish event to all listeners of a topic
    /// - Parameters:
    ///   - message: The data to deliver to all subscribers. Must be a valid JSON data type or nil.
    ///   - topic: The topic to publish to
    @objc(publishMessage:toTopic:) public static func publish(message: Any?, topic: String) {
        guard let data = message else { return PortalsPubSub.publish(to: topic) }
        guard let value = coerceToJsValue(data) else { return print("\(data) is not a valid JSON type...not publishing") }
        PortalsPubSub.publish(value, to: topic)
    }
    
    // This is needed because NSDictionary, NSArray, NSString, NSDate do not coerce to their bridged types when their bridged types conform to JSValue, so we need to do so here.
    // We could avoid doing this by making JSTypes.coerceToJSValue(_:formattingDates:) public in Capacitor.
    internal static func coerceToJsValue(_ value: Any) -> JSValue? {
        switch value {
        case let dict as NSDictionary:
            return JSTypes.coerceDictionaryToJSObject(dict)
        case let array as [Any]:
            return JSTypes.coerceArrayToJSArray(array)
        case let jsValue as JSValue:
            return jsValue
        case let string as String:
            return string
        case let date as Date:
            return date
        default:
            return nil
        }
    }
}
