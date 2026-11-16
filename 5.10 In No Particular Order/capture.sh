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

# ---- 5.10 In No Particular Order ----
# Builds with each folder's Makefile. ORDER=unsafe links the same code in a different order.
prepare
AF=AudioFilters

make_build Baseline 01-Baseline-build.txt
record 01-Baseline-run.txt 60 "Baseline/build/$AF"

make_build WithChorus 02-WithChorus-build-safe.txt
record 02-WithChorus-run-safe.txt 60 "WithChorus/build/safe/$AF"
record 03-WithChorus-lldb-destructor-order.txt 120 lldb --batch \
  -o "breakpoint set -n OutputChain::~OutputChain -C bt -G true" \
  -o "breakpoint set -n Delay::~Delay -C \"frame info\" -G true" \
  -o "breakpoint set -n DelayLineFactory::release -C \"frame info\" -G true" \
  -o "breakpoint set -n DelayLineFactory::~DelayLineFactory -C bt -G true" \
  -o "run" -k "bt" -k "quit" -- "WithChorus/build/safe/$AF" < /dev/null

make_build WithChorus 04-WithChorusUnsafe-build.txt ORDER=unsafe
record 04-WithChorusUnsafe-run.txt 60 "WithChorus/build/unsafe/$AF"
record 05-WithChorusUnsafe-lldb-bt.txt 120 lldb --batch -o "run" -k "thread list" -k "bt" -k "quit" \
  -- "WithChorus/build/unsafe/$AF" < /dev/null

ASAN='-std=c++20 -Wall -Wextra -g -fsanitize=address'
make_build WithChorus 06-WithChorusUnsafe-asan-build.txt ORDER=unsafe "CXXFLAGS=$ASAN"
record 06-WithChorusUnsafe-asan-run.txt 120 "WithChorus/build/unsafe/$AF"
record 06-WithChorusUnsafe-asan-init-order.txt 120 env ASAN_OPTIONS=check_initialization_order=1 "WithChorus/build/unsafe/$AF"
(cd WithChorus && make clean > /dev/null 2>&1)

make_build WithChorusFixed 07-WithChorusFixed-build-safe.txt
record 07-WithChorusFixed-run-safe.txt 60 "WithChorusFixed/build/safe/$AF"
make_build WithChorusFixed 08-WithChorusFixed-build-unsafe.txt ORDER=unsafe
record 08-WithChorusFixed-run-unsafe.txt 60 "WithChorusFixed/build/unsafe/$AF"
finish
