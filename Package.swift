// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", "0.5.0"..<"0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", .upToNextMajor(from: "1.0.2"))
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "IonicLiveUpdates", package: "ionic-live-updates-releases")
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
