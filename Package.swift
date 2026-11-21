// swift-tools-version: 5.9

// AppDoor iOS SDK — open-source alternative to Branch.io, AppsFlyer OneLink,
// and Firebase Dynamic Links. Deferred deep linking, mobile attribution, and
// smart link routing for iOS. Self-hosted, privacy-first, no per-click pricing.
// https://github.com/woosu-xyz/appdoor

import PackageDescription

let package = Package(
    name: "AppDoorSDK",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // The main AppDoor SDK library
        .library(
            name: "AppDoorSDK",
            targets: ["AppDoorSDK"]
        ),
    ],
    dependencies: [
        // No external dependencies - keeping it lightweight
    ],
    targets: [
        // Main SDK target
        .target(
            name: "AppDoorSDK",
            dependencies: [],
            path: "Sources/AppDoorSDK",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        ),

        // Unit tests
        .testTarget(
            name: "AppDoorSDKTests",
            dependencies: ["AppDoorSDK"],
            path: "Tests/AppDoorSDKTests"
        ),
    ]
)
