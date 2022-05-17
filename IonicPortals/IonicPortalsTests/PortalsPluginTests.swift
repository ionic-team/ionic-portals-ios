//
//  PortalsPluginTests.swift
//  PortalsPluginTests
//
//  Created by Thomas Vidas on 7/13/21.
//

import XCTest
import IonicPortals
import Capacitor
import Combine

class PortalsPluginTests: XCTestCase {
    func test_topicPublisher__when_SubscriptionResults_are_published__they_are_emitted_to_downstream_subscribers() {
        var results: [SubscriptionResult] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:result"
       
        // SUT
        PortalsPubSub.publisher(for: topic)
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPubSub.publish(1, to: topic)
        XCTAssertEqual(results.count, 1)
        
        PortalsPubSub.publish(2, to: topic)
        XCTAssertEqual(results.count, 2)
        
        PortalsPubSub.publish(3, to: topic)
        XCTAssertEqual(results.count, 3)
    }
    
    func test_topicPublisher__when_data_operator_is_called__only_the_data_is_emitted_to_downstream_subscribers() {
        var results: [JSValue] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:number:data"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .data()
            .compactMap { $0 }
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPubSub.publish(1, to: topic)
        PortalsPubSub.publish(2, to: topic)
        PortalsPubSub.publish(3, to: topic)
        
        XCTAssertEqual(results.count, 3)
    }
    
    func test_topicPublisher_data_as_operator__when_cast_as_a_valid_type__then_values_are_not_nil() {
        var results: [Int?] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:number:dataAs"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPubSub.publish(1, to: topic)
        XCTAssertEqual(results, [1])
        
        PortalsPubSub.publish(2, to: topic)
        XCTAssertEqual(results, [1, 2])
        
        PortalsPubSub.publish(3, to: topic)
        XCTAssertEqual(results, [1, 2, 3])
    }
    
    func test_topicPublisher_data_as_operator__when_cast_as_an_invalid_type__then_downstream_values_are_nil() {
        var results: [Int?] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:number:dataAs"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPubSub.publish("hello", to: topic)
        XCTAssertEqual(results, [nil])
        
        PortalsPubSub.publish(59.03, to: topic)
        XCTAssertEqual(results, [nil, nil])
        
        PortalsPubSub.publish(true, to: topic)
        XCTAssertEqual(results, [nil, nil, nil])
    }
    
    func test_topicPublisher_data_as_operator__when_receiving_heterogenous_data__then_types_not_matching_the_cast_are_nil() {
        var results: [Int?] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:number:dataAs"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPubSub.publish(1, to: topic)
        XCTAssertEqual(results, [1])
        
        PortalsPubSub.publish(59.03, to: topic)
        XCTAssertEqual(results, [1, nil])
        
        PortalsPubSub.publish(true, to: topic)
        XCTAssertEqual(results, [1, nil, nil])
    }
    
    func test_topicPublisher_tryData_as_operator__when_a_valid_type_is_cast__then_no_error_is_emitted_downstream() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:number:tryDataAs:success"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .tryData(as: Int.self)
            .assertNoFailure()
            .sink { results.append($0) }
            .store(in: &cancellables)
       
        PortalsPubSub.publish(1, to: topic)
        
        XCTAssertEqual(results, [1])
    }
    
    func test_topicPublisher_tryData_as_operator__when_an_invalid_type_is_cast__then_an_error_is_emitted_and_the_publisher_completes() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()
        var completed = false
        let topic = "test:number:tryDataAs:failure"
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .tryData(as: Int.self)
            .catch { error in
                Just(-1)
            }
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )
            .store(in: &cancellables)
        
        PortalsPubSub.publish("hello", to: topic)
        
        XCTAssertEqual(results, [-1])
        XCTAssertTrue(completed)
    }
    
    struct MagicTheGatheringCard: Codable, Equatable {
        var name: String
        var manaCost: String
        var convertedManaCost: Int8
    }
    
    func test_topicPublisher_decodeData_operator__when_well_formed_data_is_received__then_the_value_is_decoded_and_emitted_downstream() throws {
        var results: [MagicTheGatheringCard] = []
        var cancellables = Set<AnyCancellable>()
        let topic = "test:decoding:wellformed"
        
        let card = MagicTheGatheringCard(
            name: "Counterspell",
            manaCost: "{U}{U}",
            convertedManaCost: 2
        )
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .decodeData(MagicTheGatheringCard.self, decoder: JSONDecoder())
            .assertNoFailure()
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        let jsObject = try JSONEncoder().encodeJSObject(card)
        PortalsPubSub.publish(jsObject, to: topic)
        
        XCTAssertEqual(results, [card])
    }
    
    func test_topicPublisher_decodeData_operator__when_malformed_data_is_received__then_an_error_is_emitted_downstream_and_the_publisher_completes() {
        var results: [MagicTheGatheringCard] = []
        var cancellables = Set<AnyCancellable>()
        var completed = false
        let topic = "test:decoding:malformed"
        
        let emptyCard = MagicTheGatheringCard(name: "", manaCost: "", convertedManaCost: 0)
        
        // SUT
        PortalsPubSub.publisher(for: topic)
            .decodeData(MagicTheGatheringCard.self, decoder: JSONDecoder())
            .replaceError(with: emptyCard)
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )
            .store(in: &cancellables)
        
        PortalsPubSub.publish(99.82, to: topic)
        
        XCTAssertEqual(results, [emptyCard])
        XCTAssertTrue(completed)
    }
    
    func test_subscribeTo__does_not_fire_callback__when_cancellable_is_deallocated() {
        let expectation = self.expectation(description: "Callback should not have fired")
        expectation.isInverted = true
        
        var cancellable: AnyCancellable? = PortalsPubSub.subscribe(to: "test:cancellable") { _ in
            expectation.fulfill()
        }
        
        cancellable = nil
        
        PortalsPubSub.publish(to: "test:cancellable")
        wait(for: [expectation], timeout: 1.0)
        
    }
    
    #if compiler(>=5.6)
    func test_asyncSubscribe__when_values_are_published__they_are_able_to_be_manipulated_with_async_sequence_apis() async {
        let sut = Task {
            await PortalsPubSub.subscribe(to: "test:asyncstream")
                .map { $0.data }
                .prefix(2)
                .first { _ in true }
        }
        
        Task {
            // For whatever reason, the publish method is consistently
            // being called first. In practice, it is extremely unlikely that
            // subscribers and publishers will be racing at the level of nanoseconds
            // to actually register and publish.
            try await Task.sleep(nanoseconds: 1)
            PortalsPubSub.publish(1, to: "test:asyncstream")
            PortalsPubSub.publish(2, to: "test:asyncstream")
        }
        
        guard let firstValue = await sut.value as? Int else {
            XCTFail("Awaited task value was not able to be cast as an Int")
            return
        }
        
        XCTAssertEqual(firstValue, 1)
    }
    #endif
}
