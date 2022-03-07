//
//  PortalsPlugin+Combine.swift
//  IonicPortals
//
//  Created by Steven Sherry on 3/2/22.
//

import Foundation
import Combine
import Capacitor

extension PortalsPlugin {
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
    
    class Subscription: Combine.Subscription {
        private var subscriptionReference: Int?
        private var topic: String
        private let subscriber: AnySubscriber<SubscriptionResult, Never>
        
        init<S>(_ subscriber: S, topic: String)
        where S: Subscriber, S.Input == SubscriptionResult, S.Failure == Never {
            self.subscriber = AnySubscriber(subscriber)
            self.topic = topic
            subscriptionReference = PortalsPlugin.subscribe(topic) { [weak self] result in
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
            PortalsPlugin.unsubscribe(topic, subscriptionReference!)
        }
    }
    
    public static func topicPublisher(_ topic: String) -> Publisher {
        Publisher(topic: topic)
    }
}

public extension PortalsPlugin.Publisher {
    struct CastingError<T>: Error, CustomStringConvertible {
        public let description = "Unable to cast JSValue to \(T.self)"
    }
    
   func data() -> AnyPublisher<JSValue, Never> {
        map(\.data)
            .eraseToAnyPublisher()
    }
    
    func data<T>(as type: T.Type) -> AnyPublisher<T?, Never> {
        map { $0.data as? T }
            .eraseToAnyPublisher()
    }
    
    func tryData<T>(as type: T.Type) -> AnyPublisher<T, Error> {
        tryMap { result in
            guard let data = result.data as? T else { throw CastingError<T>() }
            return data
        }
        .eraseToAnyPublisher()
    }
    
    func decodeData<T>(type: T.Type, decoder: JSONDecoder) -> AnyPublisher<T, Error> where T: Decodable {
        tryData(as: JSObject.self)
            .tryMap { try decoder.decodeJSObject(T.self, from: $0) }
            .eraseToAnyPublisher()
    }
}
