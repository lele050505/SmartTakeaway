// swift-tools-version: 5.9
//
// 本 Package 只覆盖与 UIKit/AppIntents 无关的纯逻辑（SmartTakeaway/Core），
// 目的是在任意 Mac 上用 `swift test` 运行 Swift 单元测试。
// 完整 iOS App（含 Siri/AppIntents/SwiftUI）需要在 Xcode 中新建 App 工程并加入全部源码，
// Deployment Target 设为 iOS 26.0（SnippetIntent 的最低要求）。
import PackageDescription

let package = Package(
    name: "SmartTakeawayCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SmartTakeawayCore", targets: ["SmartTakeawayCore"])
    ],
    targets: [
        .target(
            name: "SmartTakeawayCore",
            path: "SmartTakeaway/Core"
        ),
        .testTarget(
            name: "SmartTakeawayCoreTests",
            dependencies: ["SmartTakeawayCore"],
            path: "Tests/SmartTakeawayCoreTests"
        )
    ]
)
