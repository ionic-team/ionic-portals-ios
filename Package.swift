// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v13), .visionOS(.v1)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(name: "capacitor-swift-pm", path: "/Users/lordlobo/src/capacitor-swift-pm"),
        .package(name: "ionic-live-updates", path: "/Users/lordlobo/src/ionic-live-updates-releases"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", .upToNextMajor(from: "1.0.2"))
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "IonicLiveUpdates", package: "ionic-live-updates")
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
