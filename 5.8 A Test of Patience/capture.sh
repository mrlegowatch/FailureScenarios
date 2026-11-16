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

# build_x PRODUCT [swift build args...]: two attempts, the second after a clean.
SPM="$DD/swiftpm"
build_x() {
  local s=$1; shift
  local out="$DD/logs/build-$s.log"
  mkdir -p "$DD/logs"
  for a in 1 2; do
    [ $a -eq 2 ] && rm -rf "$SPM"
    if swift build -c debug --scratch-path "$SPM" --product "$s" "$@" > "$out" 2>&1; then
      return 0
    fi
    log "build $s: attempt $a failed (see ${out#$ROOT/})"
  done
  log "UNSTABLE: build $s failed twice. Stopping."
  exit 1
}
bin() { echo "$SPM/debug/$1"; }

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

# ---- 5.8 A Test of Patience ----
# Record counts are a constant in each main.swift. This script edits that constant for each
# run and puts the original back when it finishes, even if it stops early.
# Attaching lldb may ask for your password the first time (macOS developer-tools permission).
prepare
for v in Baseline Instrumentation DedupeFixed; do cp "$v/main.swift" "$DD/$v-main.swift.orig"; done
restore() { for v in Baseline Instrumentation DedupeFixed; do cp "$DD/$v-main.swift.orig" "$v/main.swift"; done; }
trap restore EXIT
set_count() { sed -i '' "s/^let recordCount = .*/let recordCount = $2/" "$1/main.swift"; }

set_count Baseline 5_000
build_x Baseline
record 01-Baseline-driver-5k.txt 120 "$(bin Baseline)"

# The "frozen" run: Instrumentation at 50,000 records, observed from outside while it runs.
set_count Instrumentation 50_000
build_x Instrumentation
"$(bin Instrumentation)" > "$EV/02-Instrumentation-driver-50k.txt" 2>&1 &
PID=$!
( sleep 400; kill "$PID" 2>/dev/null ) &     # safety stop if it never finishes
sleep 5
with_timeout 60 lldb --batch -p "$PID" -o "thread list" -o "thread backtrace all" -o "detach" \
  > "$EV/03-Instrumentation-lldb-bt.txt" 2>&1 < /dev/null
for t in 10 25 40 55; do
  sleep $((t - ${LAST:-5})); LAST=$t
  kill -INFO "$PID" 2>/dev/null
done
wait "$PID"; echo "exit: $?" >> "$EV/02-Instrumentation-driver-50k.txt"

# How the original scales: the same run at four sizes.
for n in 10_000 20_000 40_000 50_000; do
  set_count Baseline "$n"; build_x Baseline
  record "04-Baseline-scaling-$n.txt" 600 "$(bin Baseline)"
done

# The fix, at 50,000 and beyond.
for n in 50_000 500_000 5_000_000 20_000_000; do
  set_count DedupeFixed "$n"; build_x DedupeFixed
  record "05-DedupeFixed-scaling-$n.txt" 300 "$(bin DedupeFixed)"
done
# Snapshots from the fix during the largest run.
"$(bin DedupeFixed)" > "$EV/06-DedupeFixed-snapshots.txt" 2>&1 &
PID=$!
( sleep 300; kill "$PID" 2>/dev/null ) &
for i in 1 2 3; do sleep 8; kill -INFO "$PID" 2>/dev/null; done
wait "$PID"; echo "exit: $?" >> "$EV/06-DedupeFixed-snapshots.txt"
finish
