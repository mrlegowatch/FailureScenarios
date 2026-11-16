# 5.8 A Test of Patience

Companion code for the book's Chapter 5 case file "A Test of Patience." Read the case first; this project lets you reproduce it.

**Language:** Swift · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

A two-task ingestion pipeline: one task produces records, and another removes duplicates.

| Executable | What it is |
|---|---|
| `Baseline` | The pipeline as shipped |
| `Instrumentation` | The same pipeline, with the reporting added during the investigation |
| `DedupeFixed` | The corrected pipeline |

The number of records is set by `recordCount` at the top of each executable's `main.swift` (50,000 by default). The case starts with a much smaller run, so try a few sizes.

## Following along

1. Open `Package.swift` in Xcode, set `recordCount` in `Baseline/main.swift` to a small number, and run **Baseline** (⌘R). From Terminal, `swift run Baseline` does the same.
2. Set it back to 50,000 and run again. Be patient; how it behaves at this size is the case.
3. While it's running, use **Debug › Pause** in Xcode to see what every thread is doing, then continue.
4. Run **Instrumentation** at the same size. It can report on itself without stopping (next section).
5. When the case reaches its fix, run **DedupeFixed** at 50,000 and beyond.

## Asking a running program for a snapshot

`Instrumentation` and `DedupeFixed` print a one-line status report whenever they receive the signal `SIGINFO`. The easiest way to send it is from Terminal:

1. Open **Terminal**, type `cd ` (with a space), drag this folder into the window, and press Return.
2. Build once from the command line: `swift build`
3. Run it: `.build/debug/Instrumentation`
4. While it runs, press **Control-T**. Each press prints a snapshot. Press **Control-C** to stop it.

From a second Terminal window, `pgrep Instrumentation` prints the process ID, and `kill -INFO` followed by that number sends the same signal. `lldb -p` followed by that number attaches the debugger (`bt all` shows every thread; `detach`, then `quit`, leaves it running).

**On Linux,** there's no `SIGINFO` and no Control-T, so the programs listen for `SIGUSR1` instead: send it with `kill -USR1` followed by the process ID.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Timings depend heavily on the machine. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every executable, reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why. It temporarily changes `recordCount` in each `main.swift` and puts the original back when it finishes. A full run takes about five minutes. Because it attaches the debugger to a running process, macOS may ask for your password the first time.

**On Windows,** there's no signal to ask with, so the programs run without snapshots and say so. Run this case in WSL to try them.
