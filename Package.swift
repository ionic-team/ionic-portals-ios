// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor", .upToNextMajor(from: "9.0.0-beta.0")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", "0.5.0"..<"0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/ionic-team/live-update-provider-sdk", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor"),
                .product(name: "IonicLiveUpdates", package: "ionic-live-updates-releases"),
                .product(name: "LiveUpdateProvider", package: "live-update-provider-sdk")
            ]
        ),
        .testTarget(
            name: "IonicPortalsTests",
            dependencies: [ "IonicPortals" ]
        ),
        .testTarget(
            name: "IonicPortalsObjcTests",
            dependencies: [ "IonicPortals" ]
        ),
        .testTarget(
            name: "ParallelAsyncSequenceTests",
            dependencies: [ "IonicPortals", .product(name: "Clocks", package: "swift-clocks") ]
        )
    ],
    swiftLanguageModes: [.v5]
)
