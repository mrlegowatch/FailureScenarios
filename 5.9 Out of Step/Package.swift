// swift-tools-version: 6.2
//
// Companion code for the case file "Out of Step."
// Each client is an executable that decodes the fitness-streak data the way that version
// of the app did: ClientPrevious (the version that wrote the old data), ClientMock (the
// new version against its mock data), ClientCurrent (the new version against real data),
// IntegrityCheck (the check run during the investigation) and ClientFixed (the fix).
// The test targets reach the types they test through @testable import.

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
    name: "HearthTally",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "ClientPrevious", path: "ClientPrevious", swiftSettings: settings),
        .executableTarget(name: "ClientMock", path: "ClientMock", swiftSettings: settings),
        .executableTarget(name: "ClientCurrent", path: "ClientCurrent", swiftSettings: settings),
        .executableTarget(name: "IntegrityCheck", path: "IntegrityCheck", swiftSettings: settings),
        .executableTarget(name: "ClientFixed", path: "ClientFixed", swiftSettings: settings),
        .testTarget(name: "IntegrityCheckTests", dependencies: ["IntegrityCheck"],
                    path: "IntegrityCheckTests", swiftSettings: settings),
        .testTarget(name: "DiagnosticTests", dependencies: ["IntegrityCheck"],
                    path: "DiagnosticTests", swiftSettings: settings),
        .testTarget(name: "ClientFixedTests", dependencies: ["ClientFixed"],
                    path: "ClientFixedTests", swiftSettings: settings),
    ]
)
