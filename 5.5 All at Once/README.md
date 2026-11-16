# 5.5 All at Once

Companion code for the book's Chapter 5 case file "All at Once." Read the case first; this package lets you reproduce it.

**Language:** Swift · **Requires:** Swift 6.2 or later on macOS (Xcode, or the Swift toolchain on its own)

## What's here

Each folder is a complete snapshot of the same small drawing-app model, at one point in the case:

| Target | Snapshot |
|---|---|
| `Baseline` | The code as you and your coworker inherit it |
| `BuggyRefactor` | The all-at-once refactor under review |
| `Change1` … `Change4` | The refactor redone one change at a time |

Each has a matching `…Tests` target. Each change's tests also rerun the tests from the changes before it, so those folders hold copies of the earlier test files. `DiagnosticTests` holds tests written during the investigation. When you open the package in Xcode, each target gets a scheme with the same name.

## Following along

1. Open `Package.swift` in Xcode. Run the **Baseline** scheme (⌘R) and its tests (**BaselineTests**, ⌘U). From Terminal (see below), `swift run Baseline` and `swift test --filter BaselineTests` do the same.
2. Review `BuggyRefactor` the way the case does, by reading it before running it. To see the whole diff, open Terminal in this folder (see below) and run:
   ```
   diff -u Baseline/Shapes.swift BuggyRefactor/Shapes.swift
   ```
3. Then run **BuggyRefactor** and **BuggyRefactorTests**, and compare what the tests catch with what your review caught.
4. Step through **Change1** to **Change4** in order, comparing each to the one before (for example, `diff -u Change1/Shapes.swift Change2/Shapes.swift`).

**Opening Terminal in this folder:** in Finder, Control-click the folder and choose **New Terminal at Folder**. If that item isn't there, open Terminal, type `cd ` (with a space), drag the folder into the window, and press Return.

## Evidence

`Evidence/` holds the full output behind the case, numbered in the order the case uses it; the book quotes it in shortened form. The tools and OS used for the most recent capture are recorded in `Evidence/VERSIONS.txt`.

To regenerate the evidence on your own Mac, run `./capture.sh` in Terminal from this folder. It moves the current `Evidence/` into `Notes/Previous-<date>` (which git ignores), rebuilds every target with `swift build` (into `build/`), reruns each step, and logs what it did in `Evidence/CAPTURE-LOG.txt`. If a build fails twice, or a test run produces no results twice, it stops there and says why.
