// swift-tools-version: 6.2
//
// Companion code for the case file "Off to the Races."
// SessionRegistry is the registry as the case finds it, and each SessionRegistryWith...
// executable is one of the attempts to fix it. Each has a copy of the same driver
// (main.swift) and a test target holding a copy of the same diagnostic test, which reaches
// the code through @testable import.

import PackageDescription

// The actor version is the fix Swift 6 steers you toward, so it builds in Swift 6 mode, plus
// the upcoming features that Swift 6 doesn't yet turn on by default.
let current: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

// The case is about a data race that Swift 6 rejects at compile time, so every variant but
// the actor stays in Swift 5 mode, with the same upcoming features the Xcode project
// enabled (Approachable Concurrency and Member Import Visibility). That keeps the race
// buildable, so it can be run, crashed and caught.
let pinnedSwift5: [SwiftSetting] = [
    .swiftLanguageMode(.v5),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

// (executable, its folder, its settings)
let variants: [(String, String, [SwiftSetting])] = [
    ("SessionRegistry", "Baseline", pinnedSwift5),
    ("SessionRegistryWithNaiveFix", "SessionRegistryWithNaiveFix", pinnedSwift5),
    ("SessionRegistryWithNaiveFix2", "SessionRegistryWithNaiveFix2", pinnedSwift5),
    ("SessionRegistryWithRaceWidening", "SessionRegistryWithRaceWidening", pinnedSwift5),
    ("SessionRegistryWithLock", "SessionRegistryWithLock", pinnedSwift5),
    ("SessionRegistryWithActor", "SessionRegistryWithActor", current),
]

let package = Package(
    name: "SessionRegistry",
    platforms: [.macOS(.v26)],
    targets: variants.flatMap { (name, folder, settings) -> [Target] in [
        .executableTarget(name: name, path: folder, swiftSettings: settings),
        .testTarget(name: "\(name)Tests", dependencies: [.target(name: name)],
                    path: "\(name)Tests", swiftSettings: settings),
    ] }
)
