import XCTest
@testable import IonicPortals
import IonicLiveUpdates
import LiveUpdateProvider

final class PortalLiveUpdateSourceTests: XCTestCase {
    func testSyncProvider_returnsProviderSyncResult() async throws {
        let manager = MockLiveUpdateProviderManager(result: MockSyncResult())
        let portal = Portal(name: "test", liveUpdateSource: .provider(manager: manager))

        let result = try await portal.syncProvider()

        XCTAssertEqual(manager.syncCallCount, 1)
        XCTAssertTrue(result is MockSyncResult)
    }

    func testSetLiveUpdateConfiguration_doesNotReplaceExternalProvider() {
        let manager = MockLiveUpdateProviderManager()
        let portal = IONPortal(portal: Portal(name: "test", liveUpdateSource: .provider(manager: manager)))

        portal.setLiveUpdateConfiguration(appId: "app-id", channel: "production", syncImmediately: false)

        guard case .provider = portal.portal.liveUpdateSource else {
            XCTFail("Expected external provider configuration to be preserved.")
            return
        }
    }
}

private struct MockSyncResult: LiveUpdateProviderSyncResult {}

private final class MockLiveUpdateProviderManager: LiveUpdateProviderManager {
    var latestAppDirectory: URL?
    var syncCallCount = 0

    private let result: any LiveUpdateProviderSyncResult

    init(
        latestAppDirectory: URL? = nil,
        result: any LiveUpdateProviderSyncResult = MockSyncResult()
    ) {
        self.latestAppDirectory = latestAppDirectory
        self.result = result
    }

    func sync() async throws -> any LiveUpdateProviderSyncResult {
        syncCallCount += 1
        return result
    }
}
