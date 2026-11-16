#!/bin/bash
# capture.sh: regenerate this case file's Evidence/ on the current toolchain.
#
# Run from Terminal:  ./capture.sh     (or: bash capture.sh)
# The previous Evidence/ is moved to Notes/Previous-<date-time>/ first, so nothing is lost.
# Every build or test run gets two attempts (the second after a clean). If both fail,
# the script stops and says why in Evidence/CAPTURE-LOG.txt. Full build logs are in build/logs/.

cd "$(dirname "$0")" || exit 1
ROOT="$PWD"
EV="$ROOT/Evidence"
DD="$ROOT/build"
STAMP=$(date +%Y%m%d-%H%M%S)
LOG="$EV/CAPTURE-LOG.txt"
mkdir -p "$DD/logs"

log() { echo "$*" | tee -a "$LOG"; }

prepare() {
  if [ -d "$EV" ] && [ -n "$(ls -A "$EV" 2>/dev/null)" ]; then
    mkdir -p "Notes/Previous-$STAMP"
    mv "$EV"/* "Notes/Previous-$STAMP/"
  fi
  mkdir -p "$EV"
  : > "$LOG"
  {
    echo "Captured: $(date)"
    echo; xcodebuild -version
    echo; clang --version | head -1
    swift --version 2>&1 | head -1
    echo; sw_vers
    echo; uname -m
  } > "$EV/VERSIONS.txt" 2>&1
  log "Capture started $(date)"
}

# carry_forward PATTERN: copy a previous evidence file that this script can't regenerate.
carry_forward() {
  for f in "Notes/Previous-$STAMP"/$1; do
    [ -f "$f" ] && cp "$f" "$EV/" && log "carried forward (not regenerated): $(basename "$f")"
  done
}

# with_timeout SECONDS cmd...: macOS has no timeout command, so perl runs the program, waits
# for it, and stops it if it runs too long (exit status 142). A crash reports 128 + the signal
# number (139 for a segmentation fault), the same convention the shell uses.
with_timeout() {
  perl -e '
    my $t = shift; my $pid = fork();
    if ($pid == 0) { exec { $ARGV[0] } @ARGV or exit 127 }
    my $timed = 0;
    $SIG{ALRM} = sub { $timed = 1; kill "TERM", $pid; sleep 2; kill "KILL", $pid };
    alarm $t; waitpid($pid, 0); my $st = $?; alarm 0;
    exit 142 if $timed;
    exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
  ' "$@"
}

# record FILE SECONDS cmd...: run once, save stdout+stderr verbatim, then the exit status.
# Crashes and failures are results here, not errors, so there's no retry.
record() {
  local f=$1 t=$2; shift 2
  with_timeout "$t" "$@" > "$EV/$f" 2>&1
  local s=$?
  [ $s -eq 142 ] && echo "[stopped by capture.sh after ${t}s]" >> "$EV/$f"
  echo "exit: $s" >> "$EV/$f"
}

# build_x SCHEME [xcodebuild settings...]: two attempts, the second after a clean.
build_x() {
  local s=$1; shift
  local out="$DD/logs/build-$s.log"
  mkdir -p "$DD/logs"
  for a in 1 2; do
    [ $a -eq 2 ] && xcodebuild -scheme "$s" -configuration Debug -derivedDataPath "$DD" clean > /dev/null 2>&1
    if xcodebuild -scheme "$s" -configuration Debug -derivedDataPath "$DD" "$@" build > "$out" 2>&1; then
      return 0
    fi
    log "build $s: attempt $a failed (see ${out#$ROOT/})"
  done
  log "UNSTABLE: build $s failed twice. Stopping."
  exit 1
}
bin() { echo "$DD/Build/Products/Debug/$1"; }

# test_x SCHEME FILE [xcodebuild args...]: test failures (and crashes) are recorded as results.
# Only a run where no tests executed at all counts as unstable; that gets a second attempt.
# xcodebuild's console output lists which tests passed and failed; the failure messages
# themselves live in the result bundle, so they're extracted from there and appended.
test_x() {
  local s=$1 f=$2; shift 2
  local out="$DD/logs/test-$s.log" rb="$DD/results/$s.xcresult"
  mkdir -p "$DD/results" "$DD/logs"
  for a in 1 2; do
    rm -rf "$rb"
    xcodebuild -scheme "$s" -configuration Debug -derivedDataPath "$DD" -resultBundlePath "$rb" "$@" test > "$out" 2>&1
    local st=$?
    if grep -qiE '^Test (suite|case) |Executed [0-9]' "$out" && ! grep -q 'BUILD FAILED' "$out"; then
      { grep -iE '^Test (suite|case) |Executed [0-9]|Restarting after|\*\* TEST' "$out"
        echo
        echo "--- results and failure messages (from the result bundle)"
        xcrun xcresulttool get test-results tests --path "$rb" 2>/dev/null | xcrun python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("(result bundle could not be read)"); sys.exit(0)
def walk(node, depth):
    kind, name, result = node.get("nodeType", ""), node.get("name", ""), node.get("result", "")
    if kind in ("Test Suite", "Test Case", "Repetition", "Failure Message"):
        print("  " * depth + name + (" [" + result + "]" if result and kind != "Failure Message" else ""))
    for child in node.get("children", []):
        walk(child, depth + 1)
for node in data.get("testNodes", []):
    walk(node, 0)
'
        echo "exit: $st"; } > "$EV/$f"
      return 0
    fi
    log "test $s: attempt $a ran no tests (see ${out#$ROOT/})"
  done
  log "UNSTABLE: tests for $s did not run twice. Stopping."
  exit 1
}

# make_build DIR FILE [make args...]: make clean, then make, saving make's output as evidence.
# Two attempts; the step must leave an executable behind.
make_build() {
  local d=$1 f=$2; shift 2
  for a in 1 2; do
    (cd "$d" && make clean > /dev/null 2>&1)
    record "$f" 300 sh -c 'd=$1; shift; cd "$d" && make "$@"' _ "$d" "$@"
    if grep -q '^exit: 0$' "$EV/$f"; then return 0; fi
    log "make in $d: attempt $a failed (see Evidence/$f)"
  done
  log "UNSTABLE: make in $d failed twice. Stopping."
  exit 1
}

finish() { log "Capture finished $(date). Review Evidence/ and this log."; }

# ---- 5.6 A Clean Bill of Health ----
# Builds with each folder's Makefile. The program reads six numbers; these are the ones the case uses.
prepare
INPUT=$(mktemp "${TMPDIR:-/tmp}/readiness-input.XXXXXX")
printf '60\n55\n7\n8\n3\n2\n' > "$INPUT"
trap 'rm -f "$INPUT"' EXIT
RS=build/ReadinessScore

make_build Baseline 01-Baseline-build.txt
record 01-Baseline-run.txt 30 "Baseline/$RS" < "$INPUT"

[ -f LinkerError/readiness.o ] || { log "LinkerError/readiness.o is missing; restore it with: git checkout -- LinkerError/readiness.o"; exit 1; }
(cd LinkerError && make clean > /dev/null 2>&1)
record 02-LinkerError-build.txt 120 sh -c 'cd LinkerError && make'      # expected to fail at link time
record 03-LinkerError-nm-main-o.txt 30 sh -c 'cd LinkerError && nm build/main.o | grep compute_readiness'
record 03-LinkerError-nm-readiness-o.txt 30 sh -c 'cd LinkerError && nm readiness.o | grep compute_readiness'
# Recreate the stale object in a scratch copy, the way a Linux or Windows machine would with
# make stale, and check that it exports the same C-linkage symbol as the checked-in one.
SC="$DD/stale-check"; rm -rf "$SC"; mkdir -p "$SC"
cp LinkerError/Makefile LinkerError/*.cpp LinkerError/*.hpp "$SC/"
record 03-LinkerError-make-stale.txt 60 sh -c 'cd "$1" && make stale && nm readiness.o | grep compute_readiness' _ "$SC"

make_build LinkerErrorFixed 04-LinkerErrorFixed-build.txt
record 05-LinkerErrorFixed-nm-main-o.txt 30 sh -c 'cd LinkerErrorFixed && nm build/main.o | grep compute_readiness'
record 05-LinkerErrorFixed-nm-readiness-o.txt 30 sh -c 'cd LinkerErrorFixed && nm build/readiness.o | grep compute_readiness'

make_build RuntimeCrashSilent 06-RuntimeCrashSilent-build.txt
for i in 1 2 3 4 5; do record "07-RuntimeCrashSilent-run-$i.txt" 30 "RuntimeCrashSilent/$RS" < "$INPUT"; done
LINE=$(grep -n 'compute_readiness(' RuntimeCrashSilent/main.cpp | head -1 | cut -d: -f1)
record 08-RuntimeCrashSilent-lldb.txt 120 lldb --batch \
  -o "breakpoint set --file main.cpp --line $LINE" -o "process launch -i $INPUT" \
  -o "frame variable result" -o "memory region result" -o "continue" \
  -k "thread list" -k "bt" -k "quit" -- "RuntimeCrashSilent/$RS" < /dev/null

make_build RuntimeCrashLoud 09-RuntimeCrashLoud-build.txt
record 10-RuntimeCrashLoud-lldb.txt 120 lldb --batch -o "process launch -i $INPUT" \
  -k "thread list" -k "bt" -k "disassemble --pc --count 5" -k "quit" -- "RuntimeCrashLoud/$RS" < /dev/null

make_build RuntimeCrashFixed 11-RuntimeCrashFixed-build.txt
record 12-RuntimeCrashFixed-run.txt 30 "RuntimeCrashFixed/$RS" < "$INPUT"
finish
