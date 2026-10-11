#!/bin/sh
# Build Object Professional (FPC 3.2.2, Linux/Unix). Run from anywhere.
# Usage: ./build.sh [outdir]   (default: out/x86_64-<os>)
# Default CPU is 64-bit x86_64; override with CPU=i386 (or another FPC CPU).
cd "$(dirname "$0")" || exit 1
FPC=${FPC:-fpc}
CPU=${CPU:-x86_64}
OSNAME=$($FPC -iTO)
OUT=${1:-out/$CPU-$OSNAME}
UNITS=$OUT/units
BIN=$OUT/bin
mkdir -p "$UNITS" "$BIN"
failed=0

echo "=== Library units ($CPU-$OSNAME) ==="
for f in *.pas; do
  $FPC -P$CPU -Mtp -Sg -FU"$UNITS" -FE"$UNITS" -Fu. -Fi. "$f" >/dev/null || { echo "FAILED: $f"; failed=$((failed+1)); }
done

echo "=== Demos ==="
for f in oprodemo/*.pas; do
  (cd oprodemo && $FPC -P$CPU -Mtp -Sg -FU"../$UNITS" -FE"../$BIN" -Fu.. -Fi.. -Fi. "$(basename "$f")" >/dev/null) \
    || { echo "FAILED: $f"; failed=$((failed+1)); }
done

echo "Done. Failures: $failed"
[ "$failed" -eq 0 ]