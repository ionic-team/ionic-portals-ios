// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v13), .macOS(.v12)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm", .upToNextMajor(from: "4.4.0")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", "0.1.2"..<"0.3.0"),
        .package(url: "https://github.com/realm/SwiftLint", revision: "cdd891a4a29cfd3473737857385f79c972702293"),
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "IonicLiveUpdates", package: "ionic-live-updates-releases")
            ],
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "IonicPortalsTests",
            dependencies: [ "IonicPortals" ]
        ),
        .testTarget(
            name: "IonicPortalsObjcTests",
            dependencies: [ "IonicPortals" ]
        )
    ]
)
