//
//  PortalsPluginTests.swift
//  PortalsPluginTests
//
//  Created by Thomas Vidas on 7/13/21.
//

import Capacitor
import Combine
import IonicPortals
import XCTest

class PortalsPluginTests: XCTestCase {
    func test_topicPublisher__when_SubscriptionResults_are_published__they_are_emitted_to_downstream_subscribers() {
        let topic = "test:result"
       
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .assertOutputs([
                { $0.data as? Int == 1 && $0.topic == topic },
                { $0.data as? Int == 2 && $0.topic == topic },
                { $0.data as? Int == 3 && $0.topic == topic }
            ])
        
        PortalsPubSub.publish(1, to: topic)
        PortalsPubSub.publish(2, to: topic)
        PortalsPubSub.publish(3, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher__when_data_operator_is_called__only_the_data_is_emitted_to_downstream_subscribers() {
        let topic = "test:number:data"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .data()
            .assertOutputs([
                { $0 as? Int == 1 },
                { $0 as? Int == 2 },
                { $0 as? Int == 3 }
            ])
        
        PortalsPubSub.publish(1, to: topic)
        PortalsPubSub.publish(2, to: topic)
        PortalsPubSub.publish(3, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_data_as_operator__when_cast_as_a_valid_type__then_values_are_not_nil() {
        let topic = "test:number:dataAs"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .expectOutput(toBe: [1, 2, 3])
        
        PortalsPubSub.publish(1, to: topic)
        PortalsPubSub.publish(2, to: topic)
        PortalsPubSub.publish(3, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_data_as_operator__when_cast_as_an_invalid_type__then_downstream_values_are_nil() {
        let topic = "test:number:dataAs"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .expectOutput(toBe: [nil, nil, nil])
        
        PortalsPubSub.publish("hello", to: topic)
        PortalsPubSub.publish(59.03, to: topic)
        PortalsPubSub.publish(true, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_data_as_operator__when_receiving_heterogenous_data__then_types_not_matching_the_cast_are_nil() {
        let topic = "test:number:dataAs"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .data(as: Int.self)
            .expectOutput(toBe: [1, nil, nil])
        
        PortalsPubSub.publish(1, to: topic)
        PortalsPubSub.publish(59.03, to: topic)
        PortalsPubSub.publish(true, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_tryData_as_operator__when_a_valid_type_is_cast__then_no_error_is_emitted_downstream() {
        let topic = "test:number:tryDataAs:success"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .tryData(as: Int.self)
            .assertNoFailure()
            .expectOutput(toBe: 1)
       
        PortalsPubSub.publish(1, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_tryData_as_operator__when_an_invalid_type_is_cast__then_an_error_is_emitted_and_the_publisher_completes() {
        let topic = "test:number:tryDataAs:failure"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .tryData(as: Int.self)
            .expectError()
        
        PortalsPubSub.publish("hello", to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    struct MagicTheGatheringCard: Codable, Equatable {
        var name: String
        var manaCost: String
        var convertedManaCost: Int8
    }
    
    func test_topicPublisher_decodeData_operator__when_well_formed_data_is_received__then_the_value_is_decoded_and_emitted_downstream() throws {
        let topic = "test:decoding:wellformed"
        
        let card = MagicTheGatheringCard(
            name: "Counterspell",
            manaCost: "{U}{U}",
            convertedManaCost: 2
        )
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .decodeData(MagicTheGatheringCard.self, decoder: JSONDecoder())
            .assertNoFailure()
            .expectOutput(toBe: card)
        
        let jsObject = try JSONEncoder().encodeJSObject(card)
        PortalsPubSub.publish(jsObject, to: topic)
        
        wait(for: result, timeout: 1)
    }
    
    func test_topicPublisher_decodeData_operator__when_malformed_data_is_received__then_an_error_is_emitted_downstream_and_the_publisher_completes() {
        let topic = "test:decoding:malformed"
        
        // SUT
        let result = PortalsPubSub.publisher(for: topic)
            .decodeData(MagicTheGatheringCard.self, decoder: JSONDecoder())
            .expectError()
        
        PortalsPubSub.publish(99.82, to: topic)
        wait(for: result, timeout: 1)
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
