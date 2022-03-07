//
//  IonicPortalsTests.swift
//  IonicPortalsTests
//
//  Created by Thomas Vidas on 7/13/21.
//

import XCTest
import IonicPortals
import Combine

class PortalsPluginTests: XCTestCase {
    func testTopicPublisher() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()
        
        PortalsPlugin.topicPublisher("test:number")
            .sink { results.append($0.data as! Int) }
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:number", 1)
        XCTAssertEqual(results, [1])
        
        PortalsPlugin.publish("test:number", 2)
        XCTAssertEqual(results, [1, 2])
        
        PortalsPlugin.publish("test:number", 3)
        XCTAssertEqual(results, [1, 2, 3])
    }
    
    func testDataOperator() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()
        
        PortalsPlugin.topicPublisher("test:number:data")
            .data()
            .sink { results.append($0 as! Int) }
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:number:data", 1)
        XCTAssertEqual(results, [1])
        
        PortalsPlugin.publish("test:number:data", 2)
        XCTAssertEqual(results, [1, 2])
        
        PortalsPlugin.publish("test:number:data", 3)
        XCTAssertEqual(results, [1, 2, 3])
    }
    
    func testDataAsOperator() {
        var results: [Int?] = []
        var cancellables = Set<AnyCancellable>()
        
        PortalsPlugin.topicPublisher("test:number:dataAs")
            .data(as: Int.self)
            .sink { results.append($0) }
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:number:dataAs", 1)
        XCTAssertEqual(results, [1])
        
        PortalsPlugin.publish("test:number:dataAs", "hello")
        XCTAssertEqual(results, [1, nil])
        
        PortalsPlugin.publish("test:number:dataAs", 3)
        XCTAssertEqual(results, [1, nil, 3])
    }
    
    func testTryDataAsOperator() {
        var results: [Int] = []
        var cancellables = Set<AnyCancellable>()
        var completed = false
        
        PortalsPlugin.topicPublisher("test:number:tryDataAs")
            .tryData(as: Int.self)
            .catch { error in
                
                Just(-1)
            }
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:number:tryDataAs", 1)
        
        XCTAssertEqual(results, [1])
        XCTAssertFalse(completed)
        
        PortalsPlugin.publish("test:number:tryDataAs", "hello")
        
        XCTAssertEqual(results, [1, -1])
        XCTAssertTrue(completed)
    }
    
    func testDecodeDataOperator() throws {
        var results: [Bool] = []
        var cancellables = Set<AnyCancellable>()
        var completed = false
        
        struct MagicTheGatheringCard: Codable, Equatable {
            var name: String
            var manaCost: String
            var convertedManaCost: Int8
            var maybeNil: String?
            var isAThing: Bool
        }
        
        let card = MagicTheGatheringCard(
            name: "Counterspell",
            manaCost: "{U}{U}",
            convertedManaCost: 2,
            maybeNil: nil,
            isAThing: true
        )
        
        let jsObject = try JSONEncoder().encodeJSObject(card)
        
        PortalsPlugin.topicPublisher("test:decoding:wellformed")
            .decodeData(type: MagicTheGatheringCard.self, decoder: JSONDecoder())
            .map { _ in true }
            .replaceError(with: false)
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:decoding:wellformed", jsObject)
       
        XCTAssertEqual(results, [true])
        XCTAssertFalse(completed)
        
        PortalsPlugin.topicPublisher("test:decoding:malformed")
            .decodeData(type: Int.self, decoder: JSONDecoder())
            .map { _ in true }
            .replaceError(with: false)
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { results.append($0) }
            )
            .store(in: &cancellables)
        
        PortalsPlugin.publish("test:decoding:malformed", jsObject)
        
        XCTAssertEqual(results, [true, false])
        XCTAssertTrue(completed)
    }
}
