//
//  PortalsPlugin+SwiftConcurrency.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/24/22.
//

import Foundation

#if compiler(>=5.6) && canImport(_Concurrency)
extension PortalsPlugin {
    /// Subscribe to a topic and receive the events in an `AsyncStream`
    /// - Parameter topic: The topic to subscribe to
    /// - Returns: An AsyncStream emitting ``SubscriptionResult``
    public static func subscribe(_ topic: String) -> AsyncStream<SubscriptionResult> {
        AsyncStream { continuation in
            let ref = PortalsPlugin.subscribe(topic) { result in
                continuation.yield(result)
            }
            
            continuation.onTermination = { @Sendable _ in
                PortalsPlugin.unsubscribe(topic, ref)
            }
        }
    }
}
#endif
