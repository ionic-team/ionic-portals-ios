import XCTest
import IonicPortals
import Combine

final class PortalsPubSubConcurrencyTests: XCTestCase {
    func test_subscribe__when_called_concurrently_for_a_new_topic__every_subscriber_receives_the_message() {
        let pubsub = PortalsPubSub()
        let lock = NSLock()

        for index in 0..<5_000 {
            let topic = "concurrent:\(index)"
            var subscriptions: [AnyCancellable] = []
            var received = 0

            DispatchQueue.concurrentPerform(iterations: 16) { _ in
                let subscription = pubsub.subscribe(to: topic) { _ in lock.withLock { received += 1 } }
                lock.withLock { subscriptions.append(subscription) }
            }
            pubsub.publish(to: topic)

            XCTAssertEqual(received, 16, "Some subscribers to \(topic) missed the message")
        }
    }
}
