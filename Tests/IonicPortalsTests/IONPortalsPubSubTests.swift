import XCTest
import IonicPortals

final class IONPortalsPubSubTests: XCTestCase {
    func test_publish__when_given_json_compatible_objective_c_types__subscribers_receive_them() {
        let topic = "test:objc:types"
        let messages: [Any] = [
            NSString(string: "hello"),
            NSDate(),
            NSNull(),
            NSNumber(value: 10.5),
            NSArray(array: ["a", 1, 2.5]),
            NSDictionary(dictionary: ["hello": 1, "goodbye": "string"])
        ]
        let received = expectation(description: "Every message was received")
        received.expectedFulfillmentCount = messages.count

        let subscription = IONPortalsPubSub.subscribe(topic: topic) { _ in received.fulfill() }
        messages.forEach { IONPortalsPubSub.publish(message: $0, topic: topic) }

        withExtendedLifetime(subscription) {
            wait(for: [received], timeout: 1)
        }
    }
}
