import Foundation
import Capacitor

struct PortalRouter: Router {
    var index: String
    var assetMaps: [AssetMap]
    var basePath: String = ""

    func route(for path: String) -> String {
        // Resolve any "." and ".." segments so a request cannot escape basePath or an asset map's directory.
        // Done by hand because URL.standardized keeps ".." segments above the root on iOS 27
        let path = "/" + path.split(separator: "/").reduce(into: [Substring]()) { segments, segment in
            switch segment {
            case ".": break
            case "..": _ = segments.popLast()
            default: segments.append(segment)
            }
        }.joined(separator: "/")
        let pathUrl = URL(fileURLWithPath: path)
        // If there's no path extension it also means the path is empty or a SPA route
        if pathUrl.pathExtension.isEmpty {
            return basePath + "/\(index)"
        }

        return assetMaps.lazy.compactMap { $0.path(for: path) }.first ?? basePath + path
    }
}

extension AssetMap {
    func path(for virtualPath: String) -> String? {
        guard virtualPath.hasPrefix(self.virtualPath) else { return nil }
        let relativeAssetPath = virtualPath.dropFirst(self.virtualPath.count)
        // Only match whole path segments, e.g. /img must not match /imgs/logo.png
        guard relativeAssetPath.isEmpty
                || relativeAssetPath.hasPrefix("/")
                || self.virtualPath.hasSuffix("/")
        else { return nil }

        let assetUrl = "\(startDir)/\(relativeAssetPath)"
            .split(separator: "/")
            .reduce(bundle.bundleURL) { $0.appendingPathComponent(String($1)) }
        return FileManager.default.fileExists(atPath: assetUrl.path) ? assetUrl.path : nil
    }
}
