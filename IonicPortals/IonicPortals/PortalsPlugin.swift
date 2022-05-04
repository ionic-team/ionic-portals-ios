import Foundation
import Capacitor
import Combine

/// An interface that enables marshalling data to and from a ``Portal`` over an event bus
@objc(PortalsPlugin)
public class PortalsPlugin: CAPPlugin {
    private static let queue = DispatchQueue(label: "io.ionic.portals.pubsub", attributes: .concurrent)
    
    private static var subscriptions: [String: [Int: (SubscriptionResult) -> Void]] = [:]
    private static var subscriptionRef = 0
    
    // MARK: Methods used by Cap Plugin

    @objc func publishNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        let data = call.getValue("data")
        PortalsPlugin.publish(topic, data!)
        call.resolve()
    }
    
    @objc func subscribeNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        call.keepAlive = true
        let ref = PortalsPlugin.subscribe(topic, {result in
            call.resolve(result.dictionaryRepresentation)
        })
        call.resolve([
            "topic": topic,
            "subscriptionRef": ref
        ])
    }
    
    @objc func unsubscribeNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        guard let subscriptionRef = call.getInt("subscriptionRef") else {
            call.reject("subscriptionRef not provided")
            return
        }
        PortalsPlugin.unsubscribe(topic, subscriptionRef)
        call.resolve()
    }
    
    // MARK: Static methods for use by Swift app
    
    /// Subscribe to a topic and execute the provided callback when the event is received.
    /// - Parameters:
    ///   - topic: The topic to listen for events on
    ///   - callback: The code to be executed when an event is received for the topic
    /// - Returns: A subscription reference to use for unsubscribing
    /// > Tip: Using this method requires you to call ``unsubscribe(_:_:)`` when finished.
    /// Use ``subscribe(to:_:)`` to get an `AnyCancellable` that will automatically unsubscribe from the topic on deallocation.
    @objc public static func subscribe(_ topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> Int {
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
    @objc public static func subscribe(to topic: String, _ callback: @escaping (SubscriptionResult) -> Void) -> AnyCancellable {
        let ref = subscribe(topic, callback)
        return AnyCancellable { PortalsPlugin.unsubscribe(topic, ref) }
    }
    
    /// Publish event to all listeners of a topic
    /// - Parameters:
    ///   - topic: The topic to publish to
    ///   - data: The data to deliver to all subscribers. Must be a valid JSON data type.
    @objc public static func publish(_ topic: String, _ data: JSValue) {
        queue.sync {
            if let subscription = subscriptions[topic] {
                for (ref, listener) in subscription {
                    let result = SubscriptionResult(topic: topic, data: data, subscriptionRef: ref)
                    listener(result)
                }
            }
        }
    }
    
    /// Stop receiving events. This must must be called to prevent a closure from being executed indefinitely
    /// - Parameters:
    ///   - topic: The topic to unsubscribe from
    ///   - subscriptionRef: The subscriptionRef provided during subscription
    @objc public static func unsubscribe(_ topic: String, _ subscriptionRef: Int) {
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
    public var data: JSValue
    /// The reference to the subscription. Used for calling ``PortalsPlugin/unsubscribe(_:_:)``
    public var subscriptionRef: Int
    
    var dictionaryRepresentation: [String: JSValue] {
        return [
            "topic": topic,
            "data": data,
            "subscriptionRef": subscriptionRef
        ]
    }
}
