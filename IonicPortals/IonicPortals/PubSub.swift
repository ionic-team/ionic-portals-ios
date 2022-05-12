//
//  PubSub.swift
//  IonicPortals
//
//  Created by Steven Sherry on 5/12/22.
//

import Foundation
import Combine
import Capacitor

/// An interface that enables marshalling data to and from a ``Portal`` over an event bus
public enum PubSub {
    private static let queue = DispatchQueue(label: "io.ionic.portals.pubsub", attributes: .concurrent)
    
    private static var subscriptions: [String: [Int: (SubscriptionResult) -> Void]] = [:]
    private static var subscriptionRef = 0
    
    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: A subscription reference to use for unsubscribing
    /// > Tip: Using this method requires you to call ``unsubscribe(from:subscriptionRef:)`` when finished.
    /// Use ``subscribe(to:_:)`` to get an `AnyCancellable` that will automatically unsubscribe from the topic on deallocation.
    public static func subscribe(_ topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> Int {
        queue.sync {
            subscriptionRef += 1
            
            if var subscription = subscriptions[topic] {
                subscription[subscriptionRef] = callback
                subscriptions[topic] = subscription
            } else {
                let subscription = [subscriptionRef : callback]
                subscriptions[topic] = subscription
            }
            
            return subscriptionRef
        }
    }
    
    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: An `AnyCancellable` that unsubscribes from the topic when deallocated.
    public static func subscribe(to topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> AnyCancellable {
        let ref = subscribe(topic, callback)
        return AnyCancellable { unsubscribe(from: topic, subscriptionRef: ref) }
    }
    
    /// Publish event to all listeners of a topic
    /// - Parameters:
    ///   - topic: The topic to publish to
    ///   - data: The data to deliver to all subscribers. Must be a valid JSON data type. Defaults to nil.
    public static func publish(_ topic: String, message: JSValue? = nil) {
        queue.sync {
            if let subscription = subscriptions[topic] {
                for (ref, listener) in subscription {
                    let result = SubscriptionResult(topic: topic, data: message, subscriptionRef: ref)
                    listener(result)
                }
            }
        }
    }
    
    /// Stop receiving events. This must must be called to prevent a closure from being executed indefinitely
    /// - Parameters:
    ///   - topic: The topic to unsubscribe from
    ///   - subscriptionRef: The subscriptionRef provided during subscription
    public static func unsubscribe(from topic: String, subscriptionRef: Int) {
        queue.async(flags: .barrier) {
            if var subscription = subscriptions[topic] {
                subscription[subscriptionRef] = nil
                subscriptions[topic] = subscription
            }
        }
    }
    
}

/// The data emitted to a subscriber
public struct SubscriptionResult {
    /// The topic the ``SubscriptionResult`` was emitted on
    public var topic: String
    /// The value emitted
    public var data: JSValue?
    /// The reference to the subscription. Used for calling ``PubSub/unsubscribe(from:subscriptionRef:)``
    public var subscriptionRef: Int
    
    var dictionaryRepresentation: [String: JSValue?] {
        return [
            "topic": topic,
            "data": data,
            "subscriptionRef": subscriptionRef
        ]
    }
}

/// An objective-c interface that enables marshalling data to and from a ``Portal`` over an event bus
@objc public class IONPubSub: NSObject {
    private override init() { }
    
    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: A subscription reference to use for unsubscribing
    /// > Tip: Using this method requires you to call ``unsubscribe(from:subscriptionRef:)`` when finished.
    @objc(subscribeToTopic:callback:) public static func subscribe(topic: String, callback: @escaping ([String: Any]) -> Void) -> Int {
        PubSub.subscribe(topic) { result in
            callback(result.dictionaryRepresentation as [String: Any])
        }
    }
        
    @objc(publishToTopic:data:) public static func publish(topic: String, data: Any) {
        guard let data = data as? JSValue else { return }
        PubSub.publish(topic, message: data)
    }
    
    @objc(unsubscribeFromTopic:subscriptionRef:) public static func unsubscribe(_ topic: String, _ subscriptionRef: Int) {
        PubSub.unsubscribe(from: topic, subscriptionRef: subscriptionRef)
    }
    
}
