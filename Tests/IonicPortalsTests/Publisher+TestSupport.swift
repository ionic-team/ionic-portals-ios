//
//  Publisher+TestSupport.swift
//  IonicPortalsTests
//
//  Created by Steven Sherry on 5/17/22.
//

import Combine
import XCTest

extension Publisher {
    func expectOutput(
        toBe values: [Output],
        file: StaticString = #file,
        line: UInt = #line
    ) -> (AnyCancellable, XCTestExpectation) where Output: Equatable {
        let publisher = prefix(values.count).collect(values.count)
        
        let expectation = XCTestExpectation(description: "Publisher test")
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    XCTFail("Unexpected failure", file: file, line: line)
                }
            },
            receiveValue: { outputs in
                XCTAssertEqual(values, outputs, file: file, line: line)
                expectation.fulfill()
            }
        )
        
        return (cancellable, expectation)
    }
    
    func expectOutput(
        toBe value: Output,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (AnyCancellable, XCTestExpectation) where Output: Equatable {
        expectOutput(toBe: [value], file: file, line: line)
    }
    
    func assertOutputs(
        _ predicates: [(Output) -> Bool],
        file: StaticString = #file,
        line: UInt = #line
    ) -> (AnyCancellable, XCTestExpectation) {
        let publisher = prefix(predicates.count).collect(predicates.count)
        
        let expectation = XCTestExpectation(description: "Publisher test")
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    XCTFail("Unexpected failure", file: file, line: line)
                }
            },
            receiveValue: { outputs in
                for (index, (predicate, output)) in Swift.zip(predicates, outputs).enumerated() {
                    XCTAssertTrue(predicate(output), "Issue asserting on element number \(index) - \(output)", file: file, line: line)
                }
                
                expectation.fulfill()
            }
        )
        
        return (cancellable, expectation)
    }
    
    func expectError(file: StaticString = #file, line: UInt = #line) -> (AnyCancellable, XCTestExpectation) {
        let expectation = XCTestExpectation(description: "Publisher test")
        
        let cancellable = sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Should have errored", file: file, line: line)
                case .failure:
                    expectation.fulfill()
                }
            },
            receiveValue: { _ in }
        )
        
        return (cancellable, expectation)
    }
}

extension XCTestCase {
    func wait(for combineExpectation: (AnyCancellable, XCTestExpectation), timeout: TimeInterval) {
        self.wait(for: [combineExpectation.1], timeout: timeout)
    }
}
