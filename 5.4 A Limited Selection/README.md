# 5.4 A Limited Selection

Companion code for the book's Chapter 5 case file "A Limited Selection." Read the case first. The project is a small, self-contained reproduction of the mechanism, not the original incident's code.

**Languages:** Swift driver calling C-style networking code in a C++ file · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own, which builds the C++ too)

## What's here

| Executable | What it is |
|---|---|
| `LimitedSelection` | Opens a number of dummy file handles, then sets up a listening socket and waits on it with `select()` |

Source: `LimitedSelection/main.swift` (the driver) and `WaitOnSelect/waitOnSelect.cpp` (the networking code). The driver imports the networking code through `WaitOnSelect/include/waitOnSelect.h`.

## Following along

1. Open `Package.swift` in Xcode and run the **LimitedSelection** scheme (⌘R). From Terminal, `swift run LimitedSelection 1024` (for example) does the same.
2. The first command-line argument sets how many dummy file handles to open first (the default is 300). To change it: **Product › Scheme › Edit Scheme › Run › Arguments**, then add a number under **Arguments Passed On Launch**. Try a range of values as the case does.
3. By default the program includes a safety check that stops before doing anything undefined. To skip the check and see what the case describes, set the environment variable `ALLOW_FD_OVERFLOW` to `1`: in Xcode, under **Edit Scheme › Run › Arguments › Environment Variables**; from Terminal, `ALLOW_FD_OVERFLOW=1 swift run LimitedSelection 1024`. Uncheck or remove it when you're done.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. Descriptor numbers and error text can differ on other systems. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why.

**On Windows,** run this case in WSL: it uses POSIX networking (`select()` and friends) that Windows doesn't provide natively.
