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

# ---- 5.11 Nothing to Report ----
# The Baseline run is expected to stop making progress. The script looks at it from
# outside after a short wait, then stops it. lldb may ask for your password the first time.
prepare
build_x Baseline
build_x Fixed
B="$(bin Baseline)"; FX="$ROOT/Fixtures"

{ for f in "$FX"/*.csv; do
    echo "== $(basename "$f"): $(wc -l < "$f" | tr -d ' ') lines"
    head -1 "$f"
  done; } > "$EV/01-Baseline-fixtures.txt"

{ for f in "$FX"/*.csv; do
    printf '%s: ' "$(basename "$f")"
    with_timeout 30 "$B" --worker < "$f" 2>/dev/null | wc -c | tr -d ' '
  done; } > "$EV/02-Baseline-output-sizes.txt"

"$B" "$FX" > "$DD/logs/baseline-run.log" 2>&1 &
PID=$!
sleep 10
ps -ax | grep Baseline | grep -v grep > "$EV/03-Baseline-ps-plain.txt"
ps -o pid,ppid,stat,%cpu,time,command -A | grep -E -i 'baseline|defunct' | grep -v grep > "$EV/03-Baseline-ps-full.txt"
# Attach to the workers first, then the parent, and end the parent's session with
# process kill instead of detach. Detaching interrupts a blocked system call: a detached
# parent's waitpid() returns early, it drains the pipes and finishes, and the hang is gone.
# A detached worker just blocks again on the next write, since its pipe is still full.
# (Attaching to a process stopped with SIGSTOP hangs lldb on macOS, so that's not an option.)
: > "$EV/05-Baseline-lldb-worker-bt.txt"
FOUND=0
for W in $(pgrep -P "$PID"); do
  case "$(ps -o stat= -p "$W")" in *Z*) continue ;; esac
  FOUND=1
  echo "== worker $W" >> "$EV/05-Baseline-lldb-worker-bt.txt"
  with_timeout 60 lldb --batch -p "$W" -o "bt" -o "detach" >> "$EV/05-Baseline-lldb-worker-bt.txt" 2>&1 < /dev/null
done
if [ $FOUND -eq 0 ]; then
  log "no live worker found under parent $PID; process table saved to build/logs/ps-workers.log"
  ps -A -o pid,ppid,stat,command > "$DD/logs/ps-workers.log" 2>&1
fi
with_timeout 60 lldb --batch -p "$PID" -o "bt" -o "frame select 1" -o "frame variable" -o "process kill" \
  > "$EV/04-Baseline-lldb-parent-bt.txt" 2>&1 < /dev/null
pkill -P "$PID" 2>/dev/null; kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null
sleep 1
if ps -A -o command | grep -q "[B]aseline $FX"; then log "WARNING: Baseline processes still running; stop them with: pkill -f Baseline"; fi

# Fixed also writes Evidence/06-Fixed-verification.txt itself.
record 06-Fixed-run.txt 120 "$(bin Fixed)" "$FX"
[ -f "$EV/06-Fixed-verification.txt" ] || log "Fixed did not write 06-Fixed-verification.txt"
finish
