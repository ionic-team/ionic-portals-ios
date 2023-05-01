//
//  PortalsPlugin+SwiftConcurrency.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/24/22.
//

import Foundation

#if compiler(>=5.6) && canImport(_Concurrency)
extension PortalsPubSub {
    /// Subscribe to a topic and receive the events in an `AsyncStream`
    /// - Parameter topic: The topic to subscribe to
    /// - Returns: An AsyncStream emitting ``SubscriptionResult``
    public static func subscribe(to topic: String) -> AsyncStream<SubscriptionResult> {
        AsyncStream { continuation in
            let cancellable = PortalsPubSub.subscribe(to: topic) { result in
                continuation.yield(result)
            }
            
            continuation.onTermination = { @Sendable [cancellable] _ in
                cancellable.cancel()
            }
        }
    }
}
#endif
