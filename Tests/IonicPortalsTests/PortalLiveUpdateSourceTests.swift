import XCTest
@testable import IonicPortals
import LiveUpdateProvider

final class PortalLiveUpdateSourceTests: XCTestCase {
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

final class MockProviderManager: ProviderManager {
    let latestAppDirectory: URL?

    init(latestAppDirectory: URL? = nil) {
        self.latestAppDirectory = latestAppDirectory
    }

    func sync() async throws -> (any ProviderSyncResult)? { nil }
}
