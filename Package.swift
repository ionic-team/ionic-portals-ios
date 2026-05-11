// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm", .upToNextMajor(from: "8.0.0")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", "0.5.0"..<"0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", .upToNextMajor(from: "1.0.2")),
        .package(url: "https://github.com/ionic-team/live-update-provider-sdk", exact: "0.1.0-alpha.2")
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
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
    ]
)
