import Foundation
import Capacitor

@objc(PortalsPlugin)
public class PortalsPlugin: CAPPlugin {
    private static let queue = DispatchQueue(label: "io.ionic.portals.pubsub", attributes: .concurrent)
    
    private static var subscriptions: [String: [Int: ((SubscriptionResult) -> Void)]] = [:]
    private static var subscriptionRef = 0
    
    // MARK: Methods used by Cap Plugin

    @objc func publishNative(_ call: CAPPluginCall) {
        guard let topic = call.getString("topic") else {
            call.reject("topic not provided")
            return
        }
        let data = call.getAny("data")
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
            call.resolve(result.toMap())
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

    public static func subscribe(_ topic: String, _ callback: @escaping (_ result: SubscriptionResult) -> ()) -> Int {
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
    
    public static func publish(_ topic: String, _ data: Any) {
        queue.sync {
            if let subscription = subscriptions[topic] {
                for (ref, listener) in subscription {
                    let result = SubscriptionResult(topic: topic, data: data, subscriptionRef: ref)
                    listener(result)
                }
            }
        }
    }
    
    public static func unsubscribe(_ topic: String, _ subscriptionRef: Int) {
        queue.async(flags: .barrier) {
            if var subscription = subscriptions[topic] {
                subscription[subscriptionRef] = nil
                subscriptions[topic] = subscription
            }
        }
    }
            
}

public struct SubscriptionResult {
    public var topic: String
    public var data: Any
    public var subscriptionRef: Int
    
    func toMap() -> [String: Any] {
        return [
            "topic": self.topic,
            "data": self.data,
            "subscriptionRef": self.subscriptionRef
        ]
    }
}
