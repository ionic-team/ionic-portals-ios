//
//  PortalsPlugin+Combine.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/2/22.
//

import Foundation
import Combine
import Capacitor

extension PortalsPubSub {
    public struct Publisher: Combine.Publisher {
        let topic: String
        
        init(topic: String) {
            self.topic = topic
        }
        
        public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, SubscriptionResult == S.Input {
            let subscription = Subscription(subscriber, topic: topic)
            subscriber.receive(subscription: subscription)
        }
        
        public typealias Output = SubscriptionResult
        public typealias Failure = Never
    }
    
    final class Subscription: Combine.Subscription {
        private var subscriptionReference: Int?
        private let topic: String
        private let subscriber: AnySubscriber<SubscriptionResult, Never>
        
        init<S>(_ subscriber: S, topic: String)
        where S: Subscriber, S.Input == SubscriptionResult, S.Failure == Never {
            self.subscriber = AnySubscriber(subscriber)
            self.topic = topic
            subscriptionReference = PortalsPubSub.subscribe(topic) { [weak self] result in
                _ = self?.subscriber.receive(result)
            }
        }
        
        // We'll do a no-op here. For users to apply back-pressure they have to create
        // a custom Subscriber implementation. The built-in Apple subscribers of
        // Subscribers.Sink and Subscribers.Assign request unlimited elements and
        // I haven't seen any custom Subscriber usage in the wild. We can always
        // revist this if someone says they need to apply backpressure. As it stands
        // with the callback-based API, it's not as if there is any backpressure
        // that can be done there anyway.
        func request(_ demand: Subscribers.Demand) {
        }
        
        func cancel() {
            guard let ref = subscriptionReference else { return }
            PortalsPubSub.unsubscribe(from: topic, subscriptionRef: ref)
        }
    }
    
    /// Subscribes to a topic and publishes a ``SubscriptionResult`` downstream
    /// - Parameter topic: The topic to subscribe to
    /// - Returns: A ``Publisher``
    public static func publisher(for topic: String) -> Publisher {
        Publisher(topic: topic)
    }
}

extension PortalsPubSub.Publisher {
    
    /// Error to be thrown when casting from JSValue to concrete value fails
    public struct CastingError<T>: Error, CustomStringConvertible {
        public let description = "Unable to cast JSValue to \(T.self)"
    }
    
    /// Extracts the ``SubscriptionResult/data`` value from ``SubscriptionResult``
    /// - Returns: A publisher emitting the ``SubscriptionResult/data`` value from the upstream ``SubscriptionResult``
    public func data() -> AnyPublisher<JSValue?, Never> {
        map(\.data)
            .eraseToAnyPublisher()
    }
    
    /// Attempts to cast the ``SubscriptionResult/data`` value of the upstream ``SubscriptionResult``
    /// - Parameter type: The concrete `JSValue` to cast ``SubscriptionResult/data`` to
    /// - Returns: A publisher emitting the an optional value after attempting to cast the ``SubscriptionResult/data`` value to a concrete type
    public func data<T>(as type: T.Type) -> AnyPublisher<T?, Never> where T: JSValue {
        map { $0.data as? T }
            .eraseToAnyPublisher()
    }
    
    /// Attempts to cast the ``SubscriptionResult/data`` value of the upstream ``SubscriptionResult`` and throws an error if unsuccessful
    /// - Parameter type: The concrete `JSValue` to cast ``SubscriptionResult/data`` to
    /// - Returns: A publisher emitting the cast value or a ``CastingError``
    public func tryData<T>(as type: T.Type) -> AnyPublisher<T, Error> where T: JSValue {
        tryMap { result in
            guard let data = result.data as? T else { throw CastingError<T>() }
            return data
        }
        .eraseToAnyPublisher()
    }
    
    /// Attempts to decode the ``SubscriptionResult/data`` value of the upstream ``SubscriptionResult`` to any type that conforms to `Decodable`.
    /// - Parameters:
    ///   - type: The type to decode the ``SubscriptionResult/data`` value of ``SubscriptionResult`` to.
    ///   - decoder: A `JSONDecoder` to perform decoding.
    /// - Returns: A publisher emitting the decoded value or a decoding error.
    public func decodeData<T>(_ type: T.Type, decoder: JSONDecoder) -> AnyPublisher<T, Error> where T: Decodable {
        tryData(as: JSObject.self)
            .tryMap { try decoder.decodeJSObject(T.self, from: $0) }
            .eraseToAnyPublisher()
    }
}
