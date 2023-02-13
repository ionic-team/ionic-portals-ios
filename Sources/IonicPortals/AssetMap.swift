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

    internal var startDirComponents: [Substring]

    /// The liveUpdateConfig associated with the AssetMap so they can be updated.
    public var liveUpdateConfig: LiveUpdate?

    public init(
        name: String,
        virtualPath: String? = nil,
        bundle: Bundle = .main,
        startDir: String,
        liveUpdateConfig: LiveUpdate? = nil
    ) {
        self.name = name
        self.virtualPath = virtualPath ?? "/\(name)"
        self.bundle = bundle
        self.startDirComponents = startDir.split(separator: "/")
        self.liveUpdateConfig = liveUpdateConfig
    }
}

extension AssetMap {
    func path(
        for virtualPath: String,
        with liveUpdateManager: LiveUpdateManager
    ) -> String? {
        guard virtualPath.hasPrefix(self.virtualPath) else { return nil }
        let prefix = virtualPath.prefix(self.virtualPath.count)
        let relativeAssetPath = String(virtualPath[prefix.endIndex...])
        return url(forApplicationAsset: relativeAssetPath, with: liveUpdateManager)?.relativePath
    }

    private func url(
        forApplicationAsset path: String,
        with liveUpdateManager: LiveUpdateManager
    ) -> URL? {
        let assetPath: URL

        if let liveUpdateConfig = liveUpdateConfig,
            let lastestAppDir = try? liveUpdateManager.latestAppDirectory(for: liveUpdateConfig) {
             assetPath = lastestAppDir
                .appending(startDir)
                .appending(path.cleaned)
        } else {
            assetPath = bundle.bundleURL
                .appending(startDir)
                .appending(path.cleaned)
        }

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
