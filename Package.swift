// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm", .exactItem("3.5.1")),
        .package(url: "https://github.com/ionic-team/ionic-live-updates-releases", .exactItem("0.1.0")),
    ],
    targets: [
        .target(
            name: "IonicPortals",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "IonicLiveUpdates", package: "ionic-live-updates-releases")
            ],
            path: "IonicPortals/IonicPortals"
        ),
    ]
)
