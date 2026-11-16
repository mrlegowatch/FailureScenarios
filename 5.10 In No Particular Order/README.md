# 5.10 In No Particular Order

Companion code for the book's Chapter 5 case file "In No Particular Order." Read the case first; this project lets you reproduce it.

**Language:** C++ · **Build system:** a Makefile in each folder · **Requires:** Xcode (for its command-line tools) on macOS

## What's here

A small audio-effects program, `AudioFilters`, whose filters register themselves when the program starts.

| Folder | Target(s) | What it is |
|---|---|---|
| `Baseline` | `Baseline` | The program before the case begins |
| `WithChorus` | `WithChorus`, `WithChorusUnsafe` | The program with one more filter added, built two ways (below) |
| `WithChorusFixed` | `WithChorusFixed` | The corrected program |

The `WithChorus` and `WithChorusFixed` Makefiles can link the same code in two orders. `make` (or `make ORDER=safe`) builds into `build/safe/`. `make ORDER=unsafe` builds into `build/unsafe/`.

## Using Xcode

If you'd rather work in Xcode, open `AudioFilters.xcodeproj` and choose the scheme with the target's name. Each scheme runs that folder's `make` for you (⌘B), then runs the program it built (⌘R) under Xcode's debugger. The **WithChorusUnsafe** scheme passes `ORDER=unsafe`. This is a handy way to bring Xcode's editor and debugger to a codebase that builds with its own Makefiles.

## Using Terminal

1. Open **Terminal** (Applications › Utilities).
2. Type `cd ` (with a trailing space), drag a folder such as `WithChorus` from Finder into the window, and press Return.
3. Type each command and press Return:

| To… | Type |
|---|---|
| Build and run the default order | `make` then `./build/safe/AudioFilters` |
| Build and run the other order | `make ORDER=unsafe` then `./build/unsafe/AudioFilters` |
| Check the exit status of the last run | `echo $?` (zero means success) |
| Run under the debugger | `lldb ./build/unsafe/AudioFilters`, then `run`; after a stop, `bt`; `quit` exits |
| Build with AddressSanitizer | `make clean` then `make ORDER=unsafe CXXFLAGS="-std=c++17 -Wall -Wextra -g -fsanitize=address"` |
| Start over | `make clean` |

## Following along

1. Build and run `Baseline`, then `WithChorus` in its default order. Both should behave.
2. Build and run `WithChorus` with `ORDER=unsafe`. This is the failure the case investigates.
3. When the case reaches its fix, build and run `WithChorusFixed` in both orders.

To see what the fix changed: `diff -ru WithChorus WithChorusFixed`, run from this project's top folder. (`-r` compares the folders file by file.)

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Addresses, and line numbers inside system headers, can differ on other tools. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target, reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why.

## On Windows

Each folder also has a `Makefile.win` for Microsoft's C++ compiler. From a **Developer Command Prompt for Visual Studio**, in a folder, `nmake /f Makefile.win` builds `build\safe\AudioFilters.exe` (or `build\AudioFilters.exe` in `Baseline`), and `nmake /f Makefile.win ORDER=unsafe` builds the other link order. Each `Makefile.win` lists the objects in link order, and the comment at its top shows how to build with AddressSanitizer.
