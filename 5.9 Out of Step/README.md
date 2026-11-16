# 5.9 Out of Step

Companion code for the book's Chapter 5 case file "Out of Step." Read the case first; this package lets you reproduce it.

**Language:** Swift · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

Pieces of HearthTally, a habit-streak app, at different points in its history. Each target is a small command-line driver that decodes saved streak data and prints what it finds.

| Executable | What it is |
|---|---|
| `ClientPrevious` | The client before the latest release |
| `ClientMock` | The new client, decoding its own mock data |
| `ClientCurrent` | The new client, decoding data saved by the previous version |
| `IntegrityCheck` | A tool written during the investigation |
| `ClientFixed` | The corrected client |

`IntegrityCheckTests`, `DiagnosticTests`, and `ClientFixedTests` are the matching test targets. Sample data lives in `Fixtures/`. When you open the package in Xcode, each target gets a scheme with the same name.

## Following along

1. Open `Package.swift` in Xcode and run **ClientCurrent** (⌘R). This is where the bug report leads. From Terminal, `swift run ClientCurrent` does the same.
2. Run **ClientPrevious** and **ClientMock** to see how each version behaves on its own data.
3. Run **IntegrityCheck** when the case reaches it, then **ClientFixed** and the test schemes (⌘U). From Terminal, `swift test --filter DiagnosticTests` runs one test target; plain `swift test` runs all three.

**Running these drivers rewrites files.** Each driver saves its output into `Evidence/`, and `ClientPrevious` also regenerates `Fixtures/old_data.json`. To put the originals back, run `git checkout -- Evidence Fixtures` in Terminal from this folder.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why. The drivers write their own evidence files, as described above.
