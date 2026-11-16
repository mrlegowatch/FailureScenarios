#!/bin/bash
# capture-all.sh: run every case file's capture.sh in order and summarize.
# Usage:  ./capture-all.sh            (all cases)
#         ./capture-all.sh 5.6 5.10   (just these)
# One case stopping doesn't stop the others. Each case's details are in its Evidence/CAPTURE-LOG.txt.

cd "$(dirname "$0")" || exit 1
CASES="${*:-5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 5.10 5.11}"
SUMMARY=""
for c in $CASES; do
  dir=$(ls -d "$c "*/ 2>/dev/null | head -1); dir=${dir%/}
  [ -n "$dir" ] || { SUMMARY="$SUMMARY\n$c: folder not found"; continue; }
  echo; echo "################ $dir"
  start=$(date +%s)
  if "$dir/capture.sh"; then r="done"; else r="STOPPED (see $dir/Evidence/CAPTURE-LOG.txt)"; fi
  SUMMARY="$SUMMARY\n$dir: $r in $(( $(date +%s) - start ))s"
done
echo; echo "================ Summary"; printf "$SUMMARY\n"
