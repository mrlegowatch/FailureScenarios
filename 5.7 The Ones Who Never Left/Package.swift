// swift-tools-version: 6.2
//
// Companion code for the case file "The Ones Who Never Left."
// Baseline is the subscriber code as the case finds it, Instrumentation adds the
// investigation's tracking, and SubscriberFixed and its two NSHashTable variants are the
// candidate fixes. Each has a driver. The test targets reach the code through
// @testable import: BasicTests runs against Baseline, DiagnosticTests against
// Instrumentation, and each fix has its own tests. Test targets after BasicTests hold
// copies of the earlier test files, which differ only in their @testable import line.

import PackageDescription

// Swift 6 language mode, plus the upcoming features that Swift 6 doesn't yet turn on
// by default.
let settings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

// (executable, its test target)
var steps = [
    ("Baseline", "BasicTests"),
    ("Instrumentation", "DiagnosticTests"),
    ("SubscriberFixed", "SubscriberFixedTests"),
]

// The two NSHashTable candidates need the Objective-C runtime (NSHashTable and autorelease
// pools), so they're built only on Apple platforms. On Linux, the package leaves them out.
#if canImport(Darwin)
steps += [
    ("SubscriberFixedHashTableVariant", "SubscriberFixedHashTableVariantTests"),
    ("SubscriberFixedHashTablePooled", "SubscriberFixedHashTablePooledTests"),
]
#endif

let package = Package(
    name: "Subscribers",
    platforms: [.macOS(.v26)],
    targets: steps.flatMap { (executable, tests) -> [Target] in [
        .executableTarget(name: executable, path: executable, swiftSettings: settings),
        .testTarget(name: tests, dependencies: [.target(name: executable)],
                    path: tests, swiftSettings: settings),
    ] }
)
