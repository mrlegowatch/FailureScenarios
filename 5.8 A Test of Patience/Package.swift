// swift-tools-version: 6.2
//
// Companion code for the case file "A Test of Patience."
// Each folder is one version of the dedupe ingest, built as its own executable.

import PackageDescription

// Swift 6 language mode, plus the upcoming features expected to become defaults in the
// next language mode, so the examples keep up with the language.
let settings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "DedupeIngest",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "Baseline", path: "Baseline", swiftSettings: settings),
        .executableTarget(name: "Instrumentation", path: "Instrumentation", swiftSettings: settings),
        .executableTarget(name: "DedupeFixed", path: "DedupeFixed", swiftSettings: settings),
    ]
)
