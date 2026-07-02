import XCTest
@testable import IonicPortals
import IonicLiveUpdates
import LiveUpdateProvider

final class PortalLiveUpdateSourceTests: XCTestCase {
    func testSyncProvider_returnsProviderSyncResult() async throws {
        let manager = MockProviderManager(result: MockSyncResult())
        let portal = Portal(name: "test", liveUpdateSource: .provider(manager: manager))

        let result = try await portal.syncProvider()

        XCTAssertEqual(manager.syncCallCount, 1)
        XCTAssertTrue(result is MockSyncResult)
    }

    func testSyncProvider_returnsNilWhenNoUpdateAvailable() async throws {
        let manager = MockProviderManager(result: nil)
        let portal = Portal(name: "test", liveUpdateSource: .provider(manager: manager))

        let result = try await portal.syncProvider()

        XCTAssertEqual(manager.syncCallCount, 1)
        XCTAssertNil(result)
    }

    func testSetLiveUpdateConfiguration_doesNotReplaceExternalProvider() {
        let manager = MockProviderManager()
        let portal = IONPortal(portal: Portal(name: "test", liveUpdateSource: .provider(manager: manager)))

        portal.setLiveUpdateConfiguration(appId: "app-id", channel: "production", syncImmediately: false)

        guard case .provider = portal.portal.liveUpdateSource else {
            XCTFail("Expected external provider configuration to be preserved.")
            return
        }
    }
}

private struct MockSyncResult: ProviderSyncResult {}

private final class MockProviderManager: ProviderManager {
    var latestAppDirectory: URL?
    var syncCallCount = 0

    private let result: (any ProviderSyncResult)?

    init(
        latestAppDirectory: URL? = nil,
        result: (any ProviderSyncResult)? = MockSyncResult()
    ) {
        self.latestAppDirectory = latestAppDirectory
        self.result = result
    }

    func sync() async throws -> (any ProviderSyncResult)? {
        syncCallCount += 1
        return result
    }
}
