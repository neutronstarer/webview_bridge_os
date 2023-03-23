// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebViewBridge",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WebViewBridge",
            targets: ["WebViewBridge"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/neutronstarer/npc_swift.git", from: "4.7.5")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WebViewBridge",
            dependencies: [
                .product(name: "NPC", package: "npc_swift")
            ],
            path: "WebViewBridge",
            exclude: [
                "Resources/webview_bridge.umd.development.js",
                "Resources/webview_bridge.umd.production.min.js"
            ],
            resources: [
                .process("Resources/webview_bridge.umd.development.js"),
                .process("Resources/webview_bridge.umd.production.min.js")
            ]
        )
    ]
)
