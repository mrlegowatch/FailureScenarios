// swift-tools-version: 6.2
//
// Companion code for the case file "The Phantom Eviction."
// FixedSizeCache is the cache as the case finds it; FixedSizeCacheFixed is the corrected
// cache. Each has a driver and the same unit tests.

import PackageDescription

// Swift 6 language mode, plus the upcoming features that Swift 6 doesn't yet turn on
// by default.
let settings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "FixedSizeCache",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "FixedSizeCache", path: "FixedSizeCache", swiftSettings: settings),
        .testTarget(name: "FixedSizeCacheTests", dependencies: ["FixedSizeCache"],
                    path: "FixedSizeCacheTests", swiftSettings: settings),
        .executableTarget(name: "FixedSizeCacheFixed", path: "FixedSizeCacheFixed", swiftSettings: settings),
        .testTarget(name: "FixedSizeCacheFixedTests", dependencies: ["FixedSizeCacheFixed"],
                    path: "FixedSizeCacheFixedTests", swiftSettings: settings),
    ]
)
