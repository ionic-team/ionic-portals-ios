//
//  AssetMap.swift
//  
//
//  Created by Steven Sherry on 2/7/23.
//

import Foundation

public struct AssetMap {
    /// The name to index the asset map by.
    public var name: String

    /// Any path to match via the web.
    public var virtualPath: String

    /// The bundle the shared assets reside in
    public var bundle: Bundle

    /// The directory name relative to the bundle (similar to Portals.startDir)
    public private(set) var startDir: String

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
        self.startDir = startDir.split(separator: "/").joined(separator: "/")
    }
}
