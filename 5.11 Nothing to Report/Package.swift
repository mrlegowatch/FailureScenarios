// swift-tools-version: 6.2
//
// Companion code for the case file "Nothing to Report."
// Baseline is the validator as the case finds it, and Fixed is the corrected version.
// Each is a single C++ source file. Run with no arguments, each reads Fixtures/; pass a
// different folder as the only argument to read that one instead.

import PackageDescription

let package = Package(
    name: "TrestleWatch",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "Baseline", path: "Baseline"),
        .executableTarget(name: "Fixed", path: "Fixed"),
    ],
    cxxLanguageStandard: .cxx20
)
