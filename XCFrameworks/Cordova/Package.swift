// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cordova",
    products: [
        .library(
            name: "Cordova",
            targets: ["Cordova"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "Cordova",
            path: "Cordova.xcframework"
        )
    ]
)
