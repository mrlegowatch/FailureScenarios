# 5.11 Nothing to Report

Companion code for the book's Chapter 5 case file "Nothing to Report." Read the case first; this package lets you reproduce it.

**Language:** C++ · **Requires:** macOS with Xcode, or the Swift toolchain on its own (it builds the C++ too)

## What's here

TrestleWatch's nightly validator. A parent process starts one worker process per sensor file, sends each worker its file, and collects their reports.

| Executable | What it is |
|---|---|
| `Baseline` | The validator as it runs every night |
| `Fixed` | The corrected validator |

`Fixtures/` holds the six sensor files from the night in question. Run with no arguments, both programs read that folder; give a different folder as the only argument to read that one instead. When you open the package in Xcode, each executable gets a scheme with the same name.

## Following along

1. Open `Package.swift` in Xcode and run **Fixed** first (⌘R). It finishes quickly and prints each file's report, which shows what a normal night looks like.
2. Run **Baseline**. Give it a while. When you've seen enough, use **Debug › Pause** to see where it's stuck, then stop it with **Product › Stop** (⌘.).

   **If Baseline finishes under Xcode, run it again.** It hangs every time from Terminal, but under Xcode's debugger it sometimes finishes: the debugger can interrupt the parent's wait, which ends the hang. The case explains why. Unchecking **Edit Scheme › Run › Info › Debug executable** makes it hang every time in Xcode too.
3. The case investigates the stuck run from outside the program. Those steps are easiest in Terminal, below.

## Using Terminal

1. Open **Terminal** (Applications › Utilities). Type `cd ` (with a trailing space), drag this folder into the window, and press Return.
2. Build both versions once: `swift build`
3. Run the Baseline validator on the sensor files: `.build/debug/Baseline`
4. Open a **second** Terminal window for looking around while it runs:

| To… | Type |
|---|---|
| List the processes and their states | `ps -o pid,ppid,stat,%cpu,command -A \| grep -E 'Baseline\|defunct'` |
| Attach the debugger to a process | `lldb -p` followed by its PID (the first number in the `ps` listing) |
| See where it's stopped | `bt` |
| Let it continue, and leave the debugger | `detach`, then `quit` |

Detaching from the **parent** interrupts its wait, which ends the hang the same way Xcode's debugger can. To keep looking, attach to the worker first, and to the parent last.

5. Back in the first window, press **Control-C** to stop the validator.

**Running Fixed rewrites a file:** it saves a pass/fail line to `Evidence/06-Fixed-verification.txt`. To restore the original, run `git checkout -- Evidence` from this folder.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Process IDs differ on every run. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why. Because it attaches the debugger to running processes, macOS may ask for your password the first time.

**On Windows,** run this case in WSL: it uses POSIX processes and pipes (`fork`, `waitpid`) that Windows doesn't provide natively.
