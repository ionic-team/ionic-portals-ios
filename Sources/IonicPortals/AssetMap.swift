//
//  AssetMap.swift
//  
//
//  Created by Steven Sherry on 2/7/23.
//

import Foundation
import IonicLiveUpdates

public struct AssetMap {
    /// The name to index the asset map by.
    public var name: String

    /// Any path to match via the web.
    public var virtualPath: String

    /// The bundle the shared assets reside in
    public var bundle: Bundle

    /// The directory name relative to the bundle (similar to Portals.startDir)
    public var startDir: String {
        startDirComponents.joined(separator: "/")
    }

    private var startDirComponents: [Substring]


    /// - Parameters:
    ///   - name: The name to index the asset map by
    ///   - virtualPath: The path to match via the web, e.g. /virtual/path. If nil, it defaults to /``name``.
    ///   - bundle: The root `Bundle` the assets are located in. Defaults to Bundle.main.
    ///   - startDir: The startDir relative to the ``bundle`` the assets are located in. Similar to ``Portal/startDir``.
    public init(
        name: String,
        virtualPath: String? = nil,
        bundle: Bundle = .main,
        startDir: String
    ) {
        self.name = name
        self.virtualPath = virtualPath ?? "/\(name)"
        self.bundle = bundle
        self.startDirComponents = startDir.split(separator: "/")
    }
}

extension AssetMap {
    func path(for virtualPath: String) -> String? {
        guard virtualPath.hasPrefix(self.virtualPath) else { return nil }
        let prefix = virtualPath.prefix(self.virtualPath.count)
        let relativeAssetPath = String(virtualPath[prefix.endIndex...])
        return url(for: relativeAssetPath)?.relativePath
    }

    private func url(for path: String) -> URL? {
        let assetPath = bundle.bundleURL
            .appending(startDir)
            .appending(path.cleaned)

        guard FileManager.default.fileExists(atPath: assetPath.relativePath) else { return nil }
        return assetPath
    }
}

extension URL {
    func appending(_ pathComponent: String) -> URL {
        guard pathComponent.isNotEmpty else { return self }
        return self.appendingPathComponent(pathComponent)
    }
}

extension String {
    var cleaned: String { self.split(separator: "/").joined(separator: "/") }
}
