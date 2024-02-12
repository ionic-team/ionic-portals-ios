//
//  ParallelAsyncSequenceTests.swift
//  
//
//  Created by Steven Sherry on 2/12/24.
//

@testable import IonicPortals
import XCTest
import Clocks


@available(iOS 16, *)
final class ParallelAsyncSequenceTests: XCTestCase {
    func testParallelAsyncSequence_runsTasksInParallel_andCompletesSuccessfullyWhenNoCancellationOccurs() async throws {
        let clock = TestClock()
        let sequence = ParallelAsyncSequence(work: [1, 2, 3, 4, 5]
            .map { number in
                return {
                    try? await clock.sleep(for: .seconds(number))
                    return number
                }
            }
        )

        let task = Task {
            await sequence.reduce(0, +)
        }

        // If the work was not being done in parallel, advancing the clock by 5 seconds would
        // not be enough to ensure the work would be completed.
        await clock.advance(by: .seconds(5))
        // This will throw if anything is currently awaiting the clock so the test will
        // fail instead of hanging indefinitely
        try await clock.checkSuspension()

        let result = await task.value
        XCTAssertEqual(result, 15)
    }

    func testParallelAsyncSequence_finishesAndCancelsTasks_whenTopLevelTaskIsCancelled() async throws {
        let clock = TestClock()
        let sequence = ParallelAsyncSequence(work: [1, 2, 3, 4, 5]
            .map { number in
                return {
                    do {
                        try await clock.sleep(for: .seconds(number))
                        return number
                    } catch is CancellationError {
                        return 0
                    } catch {
                        XCTFail("Unexpected error thrown from call to clock.sleep")
                        return 0
                    }
                }
            }
        )

        let task = Task {
            await sequence.reduce(0, +)
        }

        await clock.advance(by: .seconds(2))
        task.cancel()
        let value = await task.value
        // The reduction should have only had a chance to reduce the first two elements before the task was cancelled
        XCTAssertEqual(value, 3)
    }

}
