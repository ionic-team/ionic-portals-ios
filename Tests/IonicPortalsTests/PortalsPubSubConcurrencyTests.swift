import XCTest
@testable import IonicPortals

final class PortalsPubSubConcurrencyTests: XCTestCase {
    func test_subjectFor__when_called_concurrently_for_a_new_topic__every_caller_receives_the_same_subject() {
        let pubsub = PortalsPubSub()
        let lock = NSLock()

        for index in 0..<5_000 {
            let topic = "concurrent:\(index)"
            var subjects: [ObjectIdentifier] = []

            DispatchQueue.concurrentPerform(iterations: 16) { _ in
                let subject = pubsub.subject(for: topic)
                lock.withLock { subjects.append(ObjectIdentifier(subject)) }
            }

            XCTAssertEqual(Set(subjects).count, 1, "Multiple subjects were created for \(topic)")
        }
    }
}
