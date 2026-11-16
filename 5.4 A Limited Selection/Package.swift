// swift-tools-version: 6.2
//
// Companion code for the case file "A Limited Selection."
// LimitedSelection is a Swift driver that opens a number of dummy file handles, then calls
// waitOnSelect(), C-style networking code in a C++ file (the WaitOnSelect target), which
// sets up a listening socket and waits on it with select().

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
    name: "LimitedSelection",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "WaitOnSelect", path: "WaitOnSelect"),
        .executableTarget(name: "LimitedSelection", dependencies: ["WaitOnSelect"],
                          path: "LimitedSelection", swiftSettings: settings),
    ],
    cxxLanguageStandard: .cxx20
)
