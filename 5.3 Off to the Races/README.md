# 5.3 Off to the Races

Companion code for the book's Chapter 5 case file "Off to the Races." Read the case first; this package lets you reproduce it.

**Language:** Swift, built in **Swift 5 language mode** on purpose (except the actor version) · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

One driver is built against six versions of a session registry. Each folder holds one version of `SessionRegistry.swift` and an identical copy of the driver, `main.swift`:

| Target | Registry version |
|---|---|
| `SessionRegistry` | As the case finds it (source in `Baseline/`) |
| `SessionRegistryWithNaiveFix` | First attempt at a fix |
| `SessionRegistryWithNaiveFix2` | Second attempt |
| `SessionRegistryWithRaceWidening` | Second attempt, with a testing hook that adds random delays |
| `SessionRegistryWithLock` | Lock-based fix |
| `SessionRegistryWithActor` | Actor-based fix |

Each has a matching `…Tests` target that runs the same diagnostic test against that version; the copies differ only in their `@testable import` line. `SessionRegistryTests` tests the original. When you open the package in Xcode, each target gets a scheme with the same name.

## Following along

1. Open `Package.swift` in Xcode and run the **SessionRegistry** scheme (⌘R) several times. Expect a crash most runs, and expect it to look different from run to run. From Terminal, `swift run SessionRegistry` does the same.
2. To use Thread Sanitizer: **Product › Scheme › Edit Scheme › Run › Diagnostics**, check **Thread Sanitizer**, and run again. From Terminal: `swift run --sanitize=thread SessionRegistry`.
3. Work through the versions in the order above, running each driver and its `…Tests` scheme (⌘U) as the case reaches it. From Terminal, `swift test --filter SessionRegistryWithLockTests` (for example) runs one version's tests. These failures are sporadic, so run each one several times.
4. The random delays are off unless the environment variable `SESSIONREGISTRY_ADD_DELAY=1` is set. In Xcode, set it in **Edit Scheme › Test › Arguments › Environment Variables** for **SessionRegistryWithRaceWideningTests** (and under **Run** for a driver). From Terminal, put it in front of the command: `SESSIONREGISTRY_ADD_DELAY=1 swift test --filter SessionRegistryWithRaceWideningTests`.

**Why Swift 5?** Under Swift 6 the compiler refuses to build the original registry at all, which is exactly the argument the case makes. The actor version, the fix Swift 6 steers you toward, builds in Swift 6 mode. To see the refusal for yourself, run `swift build --product SessionRegistry -Xswiftc -swift-version -Xswiftc 6` in Terminal, or change `pinnedSwift5` to Swift 6 in `Package.swift`.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Crash details vary from run to run. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step (repeated test runs are separate `swift test` runs, so a crash ends only its own run), and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why. The Thread Sanitizer runs sometimes hang inside the sanitizer itself; the script stops each one after three minutes, so a full run can take ten minutes or more.

**On Windows,** everything builds and runs except Thread Sanitizer, which Swift doesn't support there.
