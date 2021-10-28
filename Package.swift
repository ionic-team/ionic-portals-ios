// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "IonicPortals",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "IonicPortals",
            targets: ["IonicPortals", "Capacitor"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IonicPortals",
            path: "IonicPortals/IonicPortals",
            resources: [
                .process("IonicPortals/IonicPortals/Info.plist"),
                .process("IonicPortals/IonicPortals/UnregisteredView.storyboard"),
            ]
        ),
        .binaryTarget(
            name: "Capacitor",
            path: "Capacitor.xcframework"
        )
    ]
)
