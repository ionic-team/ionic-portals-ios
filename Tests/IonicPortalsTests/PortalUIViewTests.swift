import XCTest
import WebKit
@testable import IonicPortals
import Capacitor

@MainActor
final class PortalUIViewTests: XCTestCase {
    // Fixtures/webapp is copied into the test bundle, so a portal named "webapp" loads it
    private let fixture = Portal(name: "webapp", bundle: .module)

    func test_init__when_the_start_file_exists__it_loads_the_portal_from_the_bundle() async throws {
        let webView = try makeWebView(for: fixture)

        let title = try await waitForTitle(in: webView)
        XCTAssertEqual(title, "Bundled")
    }

    func test_init__when_a_live_update_is_available__it_loads_the_live_update_instead_of_the_bundle() async throws {
        let liveUpdate = try makeLiveUpdate(title: "Live update")
        var portal = fixture
        portal.liveUpdateSource = .provider(manager: MockProviderManager(latestAppDirectory: liveUpdate))
        let webView = try makeWebView(for: portal)

        let title = try await waitForTitle(in: webView)
        XCTAssertEqual(title, "Live update")
    }

    func test_init__when_the_start_file_is_missing__it_does_not_load_anything() throws {
        let webView = try makeWebView(for: Portal(name: "missing", bundle: .module))

        XCTAssertNil(webView.url)
    }

    func test_init__it_provides_the_initial_context_before_the_page_runs() async throws {
        var portal = fixture
        portal.initialContext = ["greeting": "hello"]
        let webView = try makeWebView(for: portal)
        _ = try await waitForTitle(in: webView)

        let name = try await webView.evaluateJavaScript("window.portalInitialContext.name") as? String
        let greeting = try await webView.evaluateJavaScript("window.portalInitialContext.value.greeting") as? String
        XCTAssertEqual(name, "webapp")
        XCTAssertEqual(greeting, "hello")
    }

    func test_init__it_registers_the_portals_plugin() async throws {
        let webView = try makeWebView(for: fixture)
        _ = try await waitForTitle(in: webView)

        let available = try await webView.evaluateJavaScript("window.Capacitor.isPluginAvailable('Portals')") as? Bool
        XCTAssertEqual(available, true)
    }

    func test_init__when_appendUserAgent_is_set__it_is_appended_after_a_single_space() async throws {
        let webView = try makeWebView(for: fixture.configuring(\.appendedUserAgentString, "PortalsTests/1.0"))
        _ = try await waitForTitle(in: webView)

        let result = try await webView.evaluateJavaScript("navigator.userAgent")
        let userAgent = try XCTUnwrap(result as? String)
        XCTAssertTrue(userAgent.hasSuffix(" PortalsTests/1.0"), userAgent)
        XCTAssertFalse(userAgent.contains("  PortalsTests/1.0"), userAgent)
    }

    func test_init__by_default__pinch_zoom_is_handled_by_the_delegation_handler() throws {
        let view = makeView(for: fixture)
        let webView = try XCTUnwrap(view.bridgedWebView)

        XCTAssertTrue(webView.scrollView.delegate === view.bridge.webViewDelegationHandler)
    }

    func test_init__when_zoomEnabled_is_set__the_scroll_view_delegate_is_left_alone() throws {
        let view = makeView(for: fixture.configuring(\.zoomingEnabled, true))
        let webView = try XCTUnwrap(view.bridgedWebView)

        XCTAssertFalse(webView.scrollView.delegate === view.bridge.webViewDelegationHandler)
    }

    func test_init__programmatic_focus_does_not_require_user_interaction() throws {
        let webView = try makeWebView(for: fixture)

        XCTAssertEqual(webView.capacitor.keyboardShouldRequireUserInteraction, false)
    }

    // MARK: - Helpers

    private func makeView(for portal: Portal) -> PortalUIView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let view = PortalUIView(portal: portal)
        view.frame = window.bounds
        window.addSubview(view)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return view
    }

    private func makeWebView(for portal: Portal) throws -> WKWebView {
        try XCTUnwrap(makeView(for: portal).bridgedWebView)
    }

    /// Copies the fixture to a temporary directory, the way a live update lands on disk, with a different title
    private func makeLiveUpdate(title: String) throws -> URL {
        let source = try XCTUnwrap(Bundle.module.url(forResource: "webapp", withExtension: nil))
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: source, to: destination)
        addTeardownBlock { try? FileManager.default.removeItem(at: destination) }

        let index = destination.appendingPathComponent("index.html")
        let html = try String(contentsOf: index, encoding: .utf8)
            .replacingOccurrences(of: "<title>Bundled</title>", with: "<title>\(title)</title>")
        try html.write(to: index, atomically: true, encoding: .utf8)
        return destination
    }

    /// Waits until the portal's page has loaded, then returns its title
    /// The first load on a fresh simulator waits for WebKit to start, which takes over 10 seconds on CI
    private func waitForTitle(in webView: WKWebView, timeout: TimeInterval = 60) async throws -> String {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            // webView.url changes as soon as navigation starts, while scripts still run in about:blank,
            // which also reports "complete", so ask the document itself where it was loaded from
            let script = "location.protocol === '\(InstanceDescriptorDefaults.scheme):' && document.readyState === 'complete'"
            if let loaded = try? await webView.evaluateJavaScript(script) as? Bool, loaded {
                return try await webView.evaluateJavaScript("document.title") as? String ?? ""
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("The portal did not finish loading within \(timeout) seconds")
        return ""
    }
}
