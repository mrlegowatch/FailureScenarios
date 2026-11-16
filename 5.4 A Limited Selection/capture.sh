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

# test_x TESTTARGET[.SUITE] FILE [swift test args...]: runs one test target, or one suite in
# it (for example, MyTests.MySuite). Test failures (and crashes) are recorded as results.
# Only a run where no tests executed at all counts as unstable; that gets a second attempt.
# Build progress lines are left out of the evidence.
test_x() {
  local s=$1 f=$2; shift 2
  local out="$DD/logs/test-$s.log"
  mkdir -p "$DD/logs"
  for a in 1 2; do
    swift test -c debug --scratch-path "$SPM" --filter "^$s[./]" "$@" > "$out" 2>&1
    local st=$?
    if grep -qE 'Test run with|Executed [0-9]+ test|unexpected signal' "$out"; then
      { grep -vE '^\[[^]]*\]$|^\[[^]]*/[^]]*\]|^\[Planning|^Building for|^Build complete|^Compiling|^Write |^Planning build' "$out"
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

# ---- 5.4 A Limited Selection ----
# The program waits up to three minutes for network connections once it's set up, so each
# run is stopped after a few seconds. That stop is expected and noted at the end of each file.
prepare
build_x LimitedSelection
for n in 100 1000 1020 1024 2000; do record "01-LimitedSelection-safe-rail-$n.txt" 5 "$(bin LimitedSelection)" "$n"; done
# The same build, with the safety check turned off from the environment.
for n in 100 1000 1020 1024 2000; do record "02-LimitedSelection-fd-overflow-$n.txt" 5 env ALLOW_FD_OVERFLOW=1 "$(bin LimitedSelection)" "$n"; done
rm -f /tmp/Dummy*.txt
finish
