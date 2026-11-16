# 5.6 A Clean Bill of Health

Companion code for the book's Chapter 5 case file "A Clean Bill of Health." Read the case first; this project lets you reproduce it.

**Languages:** C, then C++ · **Build system:** a small Makefile in each folder · **Requires:** Xcode (for its command-line tools) on an Apple silicon Mac

## What's here

Each folder is one step in the case and builds a program called `ReadinessScore`, which asks for six numbers and prints a readiness score.

| Folder / target | Step |
|---|---|
| `Baseline` | The original C version |
| `LinkerError` | The port to C++, as it first fails to build |
| `LinkerErrorFixed` | The same port, building correctly |
| `RuntimeCrashSilent`, `RuntimeCrashLoud`, `RuntimeCrashFixed` | The second half of the case, in order |

**Don't delete `LinkerError/readiness.o`.** It's deliberately out of date, and that step depends on it. (`make clean` leaves it alone.) It's built for Apple silicon only. On another kind of machine, run `make stale` in `LinkerError` once to recreate it the way it was first built, with the old `extern "C"` header, then `make` as usual.

## Using Terminal

These steps work best in Terminal. If you haven't used it much:

1. Open **Terminal** (Applications › Utilities).
2. Type `cd ` (with a trailing space), drag a step's folder from Finder into the window, and press Return. You're now "in" that folder. The folder names contain spaces; dragging takes care of the quoting for you.
3. Type each command below and press Return.

| To… | Type |
|---|---|
| Build | `make` |
| Start over | `make clean`, then `make` |
| Run, typing the six numbers yourself | `./build/ReadinessScore` |
| Run with sample numbers | `printf '60\n55\n7\n8\n3\n2\n' \| ./build/ReadinessScore` |
| List a compiled file's symbols | `nm build/main.o` |
| Run under the debugger | `lldb ./build/ReadinessScore`, then `run`; after a stop, `bt` shows where; `quit` exits |

To check the exit status after a run, type `echo $?`. Zero means success.

If you'd rather work in Xcode, open `ReadinessScore.xcodeproj` and choose the scheme with the step's name. Each scheme runs that folder's `make` for you (⌘B), then runs the program it built (⌘R) under Xcode's debugger, where you can set breakpoints and look at variables. Once it's built and launched, the program waits for its six numbers. Click in Xcode's console, then type the case's numbers, pressing Return after each: `60`, `55`, `7`, `8`, `3`, `2`. (A scheme can pass arguments, but it can't feed a program's input, and these programs read their numbers as input on purpose: changing how `main` starts would change what the uninitialized pointer in the runtime-crash steps happens to hold.) **LinkerError** has nothing to run, since its point is that it doesn't link. This is a handy way to bring Xcode's editor and debugger to a codebase that builds with its own Makefiles.

## Following along

Work through the folders in the order shown in the table, building each one in Terminal and comparing what you see with the case. Compare a step's sources with the previous step's to see what changed, for example `diff -u ../Baseline/main.c main.cpp`.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Addresses can differ on other tools. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target, reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why.

## On Windows

Each folder also has a `Makefile.win` for Microsoft's C and C++ compiler. From a **Developer Command Prompt for Visual Studio**, in a step's folder, `nmake /f Makefile.win` builds `build\ReadinessScore.exe`. In `LinkerError`, run `nmake /f Makefile.win stale` once first: the checked-in `readiness.o` is a macOS object, and `stale` makes a Windows one the way the original was built. Windows names its symbols differently, so use `dumpbin /symbols readiness.obj` where the case uses `nm`, and expect the linker to report error LNK2019. Visual Studio's own Debug builds add run-time checks (`/RTC1`) that stop at the uninitialized pointer before it's used; `Makefile.win` leaves them off, like the Makefile.
