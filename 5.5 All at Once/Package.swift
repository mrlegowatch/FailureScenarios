// swift-tools-version: 6.2
//
// Companion code for the case file "All at Once."
// Baseline is the shapes code before the refactor and BuggyRefactor is the refactor as it
// landed; Change1 through Change4 redo it one change at a time. Each has a driver and its
// own tests, which reach the code through @testable import. Each change's tests include
// copies of the earlier changes' tests, so every step reruns everything before it; the
// copies differ only in their @testable import line. DiagnosticTests runs against
// BuggyRefactor.

import PackageDescription

// Swift 6 language mode, plus the upcoming features that Swift 6 doesn't yet turn on
// by default.
let settings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let steps = ["Baseline", "BuggyRefactor", "Change1", "Change2", "Change3", "Change4"]

let package = Package(
    name: "ShapeRefactor",
    platforms: [.macOS(.v26)],
    targets: steps.flatMap { step -> [Target] in [
        .executableTarget(name: step, path: step, swiftSettings: settings),
        .testTarget(name: "\(step)Tests", dependencies: [.target(name: step)],
                    path: "\(step)Tests", swiftSettings: settings),
    ] } + [
        .testTarget(name: "DiagnosticTests", dependencies: ["BuggyRefactor"],
                    path: "DiagnosticTests", swiftSettings: settings),
    ]
)
