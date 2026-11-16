# Failure Scenarios

Companion code for Chapter 5, "Failure Scenarios," of a book on debugging. Each folder reproduces one case file. Read the case first; then the folder lets you run it, break it, and fix it yourself. Each folder's own README says what's in it and how to follow along.

| Case | Language | Open with |
|---|---|---|
| 5.2 The Phantom Eviction | Swift | `Package.swift` |
| 5.3 Off to the Races | Swift (Swift 5 mode, on purpose) | `Package.swift` |
| 5.4 A Limited Selection | Swift calling C++ | `Package.swift` |
| 5.5 All at Once | Swift | `Package.swift` |
| 5.6 A Clean Bill of Health | C, then C++ | a `Makefile` per step, or `ReadinessScore.xcodeproj` |
| 5.7 The Ones Who Never Left | Swift | `Package.swift` |
| 5.8 A Test of Patience | Swift | `Package.swift` |
| 5.9 Out of Step | Swift | `Package.swift` |
| 5.10 In No Particular Order | C++ | a `Makefile` per step, or `AudioFilters.xcodeproj` |
| 5.11 Nothing to Report | C++ | `Package.swift` |

## What you need

- **Swift cases (and 5.4 and 5.11):** Swift 6.2 or later. On a Mac, that's Xcode, or the Swift toolchain on its own. Open `Package.swift` in Xcode and each target gets a scheme with the same name, or use `swift build`, `swift run` and `swift test` in Terminal.
- **Makefile cases (5.6 and 5.10):** a C and C++ compiler and `make`. On a Mac, Xcode's command-line tools provide them. The Xcode projects in these two folders run the same `make` for you, then run the program under Xcode's debugger.

The Swift code builds in Swift 6 language mode, except where a case needs the older rules to show its bug (5.3). The C++ builds as C++20.

## Evidence

Each folder's `Evidence/` holds the output behind its case, numbered in the order the case uses it; the book quotes it in shortened form. Line numbers, addresses, process IDs and timings in captured output won't always match what you see when you run the code yourself. `VERSIONS.txt` in each `Evidence/` records the tools and OS of the most recent capture.

To regenerate a case's evidence, run its `./capture.sh` in Terminal from that folder. To regenerate every case in turn, run `./capture-all.sh` from this folder, or name the cases you want: `./capture-all.sh 5.6 5.10`.

## On Linux (and a second check on macOS)

`./check.sh` builds, tests and runs every case on a Linux machine or container with Swift 6.2 or later, `make` and a C/C++ compiler, and records what happened in `check/`. It runs on macOS too, with GNU `timeout` installed (`brew install coreutils`). It leaves the case folders as they were, apart from their build output.

## On Windows (untested)

`.\check.ps1`, run from a **Developer PowerShell for Visual Studio** with Swift 6.2 or later installed, builds, tests and runs the cases that run natively on Windows, and records what happened in `check\`. 5.6 and 5.10 build with `nmake /f Makefile.win`. 5.4 and 5.11 use POSIX networking and processes, so on Windows they run in WSL, with `./check.sh 5.4 5.11`. None of this has been tried on Windows yet.

## Continuous checks

GitHub Actions runs `check.sh` on Linux and `check.ps1` on Windows on every push, and `check.sh` on macOS when started by hand from the Actions tab (see `.github/workflows/check.yml`). Each run's page shows a summary for each platform. Expected failures are part of the cases, so a run doesn't fail because a case does.
