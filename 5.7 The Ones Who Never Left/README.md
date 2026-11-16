# 5.7 The Ones Who Never Left

Companion code for the book's Chapter 5 case file "The Ones Who Never Left." Read the case first; this package lets you reproduce it.

**Language:** Swift · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

A small publish-subscribe system, with a driver that runs a few hundred work sessions and reports what's still alive afterward.

| Target | What it is |
|---|---|
| `Baseline` | The system as the case finds it |
| `Instrumentation` | The same code, with counters added during the investigation |
| `BasicTests` | The existing test suite |
| `DiagnosticTests` | A test written during the investigation |
| `SubscriberFixed` | First candidate fix |
| `SubscriberFixedHashTableVariant` | Second candidate |
| `SubscriberFixedHashTablePooled` | Second candidate, revised |

The three candidates each have a matching `…Tests` target. On Linux, the two NSHashTable candidates (and their tests) aren't built: they need the Objective-C runtime, which only Apple platforms have. The test targets after `BasicTests` hold copies of the earlier test files, so each one reruns the tests before it. When you open the package in Xcode, each target gets a scheme with the same name.

## Following along

1. Open `Package.swift` in Xcode. Run **Baseline** (⌘R) and read its summary. From Terminal, `swift run Baseline` does the same.
2. Run **Instrumentation**, then the **BasicTests** and **DiagnosticTests** schemes (⌘U). From Terminal, `swift test --filter BasicTests` runs one test target.
3. When the case turns to fixes, run each candidate and its tests in the order listed above.

Some attempts in the case don't compile at all. Those aren't targets in this project; a summary of their compiler errors is in `Evidence/05-Instrumentation-compile-failures.txt`.

**If the diagnostic test gives a different answer than the case,** that's a real effect, not a mistake. The test counts live subscribers across the whole process, and the other tests in its target run beside it and create and release subscribers of their own. Run as part of its whole target, it gets the wrong answer about one run in four, in either direction: green against the leaking code, or red against a fix. Run on its own, it's right every time:

```
swift test --filter DiagnosticTests.DiagnosticTests
```

(In Xcode, click the diamond next to the test in the Test navigator.) `Evidence/10-DiagnosticTests-tally.txt` records how often each way of running it failed in the most recent capture. *Sporadic failure strategies* in the book has more on tests that interfere with each other.

The **Debug Memory Graph** button in Xcode's debug bar is worth trying while a driver is paused at a breakpoint near the end of its run.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why. Two files are carried forward from an earlier capture rather than regenerated: `05-Instrumentation-compile-failures.txt`, a summary of attempts that don't compile and so aren't targets, and `08-SubscriberFixedHashTablePooled-driver-broadcast-pool-only.txt`, from a temporary one-line edit.
