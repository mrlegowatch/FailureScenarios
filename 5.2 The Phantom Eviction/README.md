# 5.2 The Phantom Eviction

Companion code for the book's Chapter 5 case file "The Phantom Eviction." Read the case first; this package lets you reproduce it.

**Language:** Swift · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

| Target | What it is |
|---|---|
| `FixedSizeCache` | Command-line driver for the cache as the case finds it |
| `FixedSizeCacheTests` | The cache's unit tests, run against the original cache |
| `FixedSizeCacheFixed` | The same driver, built against the corrected cache |
| `FixedSizeCacheFixedTests` | The same unit tests, run against the corrected cache |

When you open the package in Xcode, each target gets a scheme with the same name. Choose it from the scheme menu in Xcode's toolbar.

## Following along

1. Open `Package.swift` in Xcode.
2. Select the **FixedSizeCache** scheme and run it (⌘R). Read the summary it prints. From Terminal, `swift run FixedSizeCache` does the same.
3. Select **FixedSizeCacheTests** and run the tests (⌘U). Some tests are expected to fail; that's part of the case. From Terminal, `swift test --filter FixedSizeCacheTests` runs only these.
4. When the case reaches its fix, run **FixedSizeCacheFixed** and **FixedSizeCacheFixedTests** and compare. From Terminal: `swift run FixedSizeCacheFixed` and `swift test --filter FixedSizeCacheFixedTests`.

To see exactly what changed, compare `FixedSizeCache/FixedSizeCache.swift` with `FixedSizeCacheFixed/FixedSizeCache.swift`.

From Terminal, plain `swift test` runs both test targets, one after the other. It runs XCTest first, which reports "Executed 0 tests" because these tests use Swift Testing; the Swift Testing results follow it.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Your numbers may differ slightly on other tools. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why.
