// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nxfit_sync_sdk",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "nxfit-sync-sdk", targets: ["nxfit_sync_sdk"])
    ],
    dependencies: [
        .package(url: "https://github.com/NeoEx-Developer/NxFit-SDK-for-iOS", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),

    ],
    targets: [
        .target(
            name: "nxfit_sync_sdk",
            dependencies: [
                .product(name: "NXFitSync", package: "NxFit-SDK-for-iOS"),
                .product(name: "Logging", package: "swift-log")
            ],
            resources: [
                // If your plugin requires a privacy manifest, for example if it uses any required
                // reason APIs, update the PrivacyInfo.xcprivacy file to describe your plugin's
                // privacy impact, and then uncomment these lines. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                // .process("PrivacyInfo.xcprivacy"),

                // If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
