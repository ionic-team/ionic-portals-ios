import XCTest
@testable import IonicPortals

final class PortalRouterTests: XCTestCase {
    private var bundleDirectory: URL!

    override func setUpWithError() throws {
        bundleDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let imagesDirectory = bundleDirectory.appendingPathComponent("shared/images", isDirectory: true)
        // Reachable from /imagesX/logo.png if asset maps matched on a raw string prefix
        let lookalikeDirectory = imagesDirectory.appendingPathComponent("X", isDirectory: true)
        try FileManager.default.createDirectory(at: lookalikeDirectory, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: imagesDirectory.appendingPathComponent("logo.png").path, contents: Data())
        FileManager.default.createFile(atPath: lookalikeDirectory.appendingPathComponent("logo.png").path, contents: Data())
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: bundleDirectory)
    }

    private func router(assetMaps: [AssetMap] = []) -> PortalRouter {
        PortalRouter(index: "index.html", assetMaps: assetMaps, basePath: "/base")
    }

    private func imagesAssetMap(virtualPath: String? = nil) throws -> AssetMap {
        AssetMap(
            name: "images",
            virtualPath: virtualPath,
            bundle: try XCTUnwrap(Bundle(url: bundleDirectory)),
            startDir: "shared/images"
        )
    }

    func test_route__without_asset_maps__it_routes_relative_to_the_base_path() {
        XCTAssertEqual(router().route(for: "/"), "/base/index.html")
        XCTAssertEqual(router().route(for: "/some/spa/route"), "/base/index.html")
        XCTAssertEqual(router().route(for: "/assets/app.js"), "/base/assets/app.js")
    }

    func test_route__when_path_contains_parent_segments__it_cannot_escape_the_base_path() {
        XCTAssertEqual(router().route(for: "/../../etc/passwd.txt"), "/base/etc/passwd.txt")
    }

    func test_route__when_path_matches_an_asset_map__it_routes_to_the_asset() throws {
        let route = router(assetMaps: [try imagesAssetMap()]).route(for: "/images/logo.png")
        XCTAssertTrue(route.hasSuffix("/shared/images/logo.png"), route)
        XCTAssertFalse(route.hasPrefix("/base"), route)

        let trailingSlashRoute = router(assetMaps: [try imagesAssetMap(virtualPath: "/images/")]).route(for: "/images/logo.png")
        XCTAssertTrue(trailingSlashRoute.hasSuffix("/shared/images/logo.png"), trailingSlashRoute)
    }

    func test_route__when_path_only_shares_a_prefix_with_an_asset_map__it_does_not_match() throws {
        let route = router(assetMaps: [try imagesAssetMap()]).route(for: "/imagesX/logo.png")
        XCTAssertEqual(route, "/base/imagesX/logo.png")
    }
}
