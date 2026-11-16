#!/bin/bash
# check.sh: build, test and run every case on macOS or Linux, and record what happened.
# (check.ps1 is the Windows counterpart.)
#
# Needs Swift 6.2 or later, make, and a C/C++ compiler (the Swift toolchain's clang is enough;
# on macOS, Xcode or its Command Line Tools). Nothing else to install: it runs in the bash that
# macOS ships. Run from this folder:  ./check.sh
# Or name the cases you want:  ./check.sh 5.4 5.11
# Results go to check/<case>.txt, with a summary in check/SUMMARY.txt. Nothing in the case
# folders is changed, except their build output.

cd "$(dirname "$0")" || exit 1
ROOT="$PWD"
OUT="$ROOT/check"
OS=$(uname -s)
mkdir -p "$OUT"
CASES="${*:-5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 5.10 5.11}"
# Keeps this script's build output apart from Xcode's .build: .build-linux or .build-darwin.
SCRATCH=".build-$(echo "$OS" | tr '[:upper:]' '[:lower:]')"

# step LABEL SECONDS cmd...: runs one command with a time limit and records its output and
# exit status. 124 means it was stopped at the time limit; 128 + n means it died of signal n.
# limit SECONDS LOG cmd...: run cmd with its output in LOG for at most SECONDS, then stop it
# and everything it started (TERM, then KILL five seconds later) and return 124, as GNU
# timeout would. macOS doesn't ship timeout, so this does its job in plain bash.
limit() {
  local t=$1 log=$2 pid n=0; shift 2
  set -m                     # gives the command its own process group, to stop as a whole
  "$@" >> "$log" 2>&1 < /dev/null &
  pid=$!
  set +m
  trap 'kill -KILL -- -$pid 2> /dev/null; exit 130' INT TERM   # Control-C stops it too
  while kill -0 "$pid" 2> /dev/null; do
    if [ "$n" -ge $((t * 10)) ]; then
      kill -TERM -- -"$pid" 2> /dev/null
      n=0; while kill -0 "$pid" 2> /dev/null && [ "$n" -lt 50 ]; do sleep 0.1; n=$((n + 1)); done
      kill -KILL -- -"$pid" 2> /dev/null
      wait "$pid" 2> /dev/null
      return 124
    fi
    sleep 0.1; n=$((n + 1))
  done
  wait "$pid"
}

step() {
  local label=$1 t=$2; shift 2
  { echo; echo "---- $label"; echo "\$ $*"; } >> "$LOG"
  # The subshell keeps bash's own "Segmentation fault" notices out of the summary; the
  # exit status still says what happened.
  # bash -c runs the helper functions below as well as programs.
  ( limit "$t" "$LOG" bash -c '"$@"' _ "$@" ) 2> /dev/null
  local st=$?
  echo "exit: $st" >> "$LOG"
  printf '  %-58s exit %s\n' "$label" "$st" | tee -a "$OUT/SUMMARY.txt"
}
sb() { swift build --scratch-path "$SCRATCH" "$@"; }
sr() { swift run --scratch-path "$SCRATCH" --skip-build "$@"; }
st() { swift test --scratch-path "$SCRATCH" "$@"; }
export SCRATCH; export -f sb sr st

{ echo "check.sh $(date)"; uname -a; swift --version 2>&1 | head -1; cc --version 2>&1 | head -1; } > "$OUT/SUMMARY.txt"
for c in $CASES; do
  dir=$(ls -d "$c "*/ 2>/dev/null | head -1); dir=${dir%/}
  [ -n "$dir" ] || { echo "$c: folder not found" | tee -a "$OUT/SUMMARY.txt"; continue; }
  LOG="$OUT/$c.txt"; : > "$LOG"
  echo "== $dir" | tee -a "$OUT/SUMMARY.txt"
  cd "$ROOT/$dir" || continue
  case $c in
  5.2)
    step "build" 600 sb
    step "run FixedSizeCache" 60 sr FixedSizeCache
    step "run FixedSizeCacheFixed" 60 sr FixedSizeCacheFixed
    step "test FixedSizeCacheTests (2 failures expected)" 300 st --filter FixedSizeCacheTests
    step "test FixedSizeCacheFixedTests" 300 st --filter FixedSizeCacheFixedTests ;;
  5.3)
    step "build" 600 sb
    for i in 1 2 3; do step "run SessionRegistry #$i (crash expected)" 60 sr SessionRegistry; done
    step "build with Thread Sanitizer" 600 sb --sanitize=thread --product SessionRegistry
    for i in 1 2 3; do step "TSan run #$i" 120 swift run --scratch-path "$SCRATCH" --sanitize=thread --skip-build SessionRegistry; done
    step "run SessionRegistryWithLock, delays on" 60 env SESSIONREGISTRY_ADD_DELAY=1 swift run --scratch-path "$SCRATCH" --skip-build SessionRegistryWithLock
    step "run SessionRegistryWithActor, delays on" 60 env SESSIONREGISTRY_ADD_DELAY=1 swift run --scratch-path "$SCRATCH" --skip-build SessionRegistryWithActor
    for t in SessionRegistryTests SessionRegistryWithNaiveFix2Tests SessionRegistryWithLockTests SessionRegistryWithActorTests; do
      step "test $t" 300 st --filter "$t"
    done
    step "test SessionRegistryWithRaceWideningTests, delays on" 300 env SESSIONREGISTRY_ADD_DELAY=1 swift test --scratch-path "$SCRATCH" --filter SessionRegistryWithRaceWideningTests
    step "Swift 6 build of the original (refusal expected)" 600 swift build --scratch-path "$SCRATCH-swift6" --product SessionRegistry -Xswiftc -swift-version -Xswiftc 6 ;;
  5.4)
    step "build" 600 sb
    for n in 1020 1024; do step "run LimitedSelection $n" 10 bash -c "ulimit -n 4096; sr LimitedSelection $n"; done
    step "run LimitedSelection 1024, check off (waits on select: stopped)" 10 bash -c "ulimit -n 4096; ALLOW_FD_OVERFLOW=1 sr LimitedSelection 1024"
    rm -f /tmp/Dummy*.txt ;;
  5.5)
    step "build" 600 sb
    for t in Baseline BuggyRefactor Change1 Change2 Change3 Change4; do step "run $t" 60 sr "$t"; done
    step "test (BuggyRefactorTests and DiagnosticTests failures expected)" 600 st ;;
  5.6)
    for d in Baseline LinkerErrorFixed RuntimeCrashSilent RuntimeCrashLoud RuntimeCrashFixed; do
      step "make $d" 120 make -C "$d" clean all
      step "run $d" 30 sh -c "printf '60\n55\n7\n8\n3\n2\n' | $d/build/ReadinessScore"
    done
    step "make LinkerError with the checked-in macOS object (fails)" 120 make -C LinkerError clean all
    rm -rf "$OUT/5.6-stale"; mkdir -p "$OUT/5.6-stale"; cp LinkerError/Makefile LinkerError/*.cpp LinkerError/*.hpp "$OUT/5.6-stale/"
    step "make stale, then make (undefined reference expected)" 120 sh -c "cd '$OUT/5.6-stale' && make stale && nm readiness.o | grep compute_readiness && make"
    for d in Baseline LinkerError LinkerErrorFixed RuntimeCrashSilent RuntimeCrashLoud RuntimeCrashFixed; do make -C "$d" clean > /dev/null 2>&1; done ;;
  5.7)
    step "build" 600 sb
    # The NSHashTable candidates need the Objective-C runtime, so the package leaves them out
    # on Linux; on macOS they run too.
    variants="Baseline Instrumentation SubscriberFixed"
    [ "$OS" = Darwin ] && variants="$variants SubscriberFixedHashTableVariant SubscriberFixedHashTablePooled"
    for t in $variants; do step "run $t" 60 sr "$t"; done
    step "test DiagnosticTests.DiagnosticTests (failure expected)" 300 st --filter 'DiagnosticTests\.DiagnosticTests'
    for t in BasicTests SubscriberFixedTests; do step "test $t" 300 st --filter "$t"; done ;;
  5.8)
    step "build" 600 sb
    step "run DedupeFixed" 120 sr DedupeFixed
    # On Linux the snapshot signal is SIGUSR1 (macOS uses SIGINFO, which Control-T sends; the
    # Mac's capture.sh covers it). stdbuf -oL makes output line-buffered, so each snapshot
    # reaches the log before the final kill stops the program (exit 143 is that kill).
    [ "$OS" = Linux ] && step "Instrumentation, two snapshots by kill -USR1 (then stopped)" 30 bash -c \
      "stdbuf -oL $SCRATCH/debug/Instrumentation & p=\$!; sleep 3; kill -USR1 \$p; sleep 3; kill -USR1 \$p; sleep 1; kill \$p; wait \$p"
    step "run Baseline (50,000 records; slow is expected)" 300 sr Baseline ;;
  5.9)
    step "build" 600 sb
    for t in ClientPrevious ClientMock ClientCurrent IntegrityCheck ClientFixed; do step "run $t" 60 sr "$t"; done
    step "test (DiagnosticTests known issues expected)" 600 st
    git checkout -q -- Evidence Fixtures 2>/dev/null ;;
  5.10)
    step "make Baseline" 120 make -C Baseline clean all
    step "run Baseline" 30 Baseline/build/AudioFilters
    for o in safe unsafe; do
      step "make WithChorus ORDER=$o" 120 make -C WithChorus clean all ORDER=$o
      step "run WithChorus $o (unsafe crash expected)" 30 "WithChorus/build/$o/AudioFilters"
      step "make WithChorusFixed ORDER=$o" 120 make -C WithChorusFixed clean all ORDER=$o
      step "run WithChorusFixed $o" 30 "WithChorusFixed/build/$o/AudioFilters"
    done
    step "make WithChorus ORDER=unsafe with AddressSanitizer" 120 make -C WithChorus clean all ORDER=unsafe "CXXFLAGS=-std=c++20 -Wall -Wextra -g -fsanitize=address"
    step "run with check_initialization_order=1" 60 env ASAN_OPTIONS=check_initialization_order=1 WithChorus/build/unsafe/AudioFilters
    for d in Baseline WithChorus WithChorusFixed; do make -C "$d" clean > /dev/null 2>&1; done ;;
  5.11)
    step "build" 600 sb
    step "run Fixed" 60 sr Fixed
    step "run Baseline (hang expected: stopped)" 15 sr Baseline
    git checkout -q -- Evidence 2>/dev/null ;;
  esac
  cd "$ROOT"
done
echo; echo "Details are in $OUT/."
