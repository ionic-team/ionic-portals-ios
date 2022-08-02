// swift-tools-version:5.3

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
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm", .upToNextMajor(from: "3.7.0")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", .upToNextMinor(from: "0.1.3")),
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
        )
    ]
)
