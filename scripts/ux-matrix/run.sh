#!/usr/bin/env bash
# Runs LayoutMatrixUITests on a set of simulators (every screen in portrait and
# landscape) and builds an HTML report with each screenshot and layout finding.
#
# Usage:
#   scripts/ux-matrix/run.sh                          # all device classes
#   scripts/ux-matrix/run.sh iphone-small ipad-large  # just these
#   OUT_DIR=/tmp/ux scripts/ux-matrix/run.sh
#
# Device classes are defined in pick_simulators.py. Exits non-zero if any
# device had a hard failure; the report is written either way.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/build/ux-matrix}"
DERIVED_DATA="${DERIVED_DATA:-$OUT_DIR/DerivedData}"
PROJECT="$ROOT/MathQuestKids.xcodeproj"
SCHEME="MathQuestKids"
ONLY_TESTING="${ONLY_TESTING:-MathQuestKidsUITests/LayoutMatrixUITests}"
HERE="$ROOT/scripts/ux-matrix"

mkdir -p "$OUT_DIR/results" "$OUT_DIR/devices"

echo "==> Picking simulators"
python3 "$HERE/pick_simulators.py" "$@" > "$OUT_DIR/devices.tsv"
if [[ ! -s "$OUT_DIR/devices.tsv" ]]; then
  echo "No simulators matched." >&2
  exit 1
fi

echo "==> Building for testing ($(xcodebuild -version | head -1))"
set +e
xcodebuild build-for-testing \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  > "$OUT_DIR/build.log" 2>&1
status=$?
set -e
if [[ $status -ne 0 ]]; then
  grep -E "error:|\*\* BUILD" "$OUT_DIR/build.log" | head -60 || tail -80 "$OUT_DIR/build.log"
  echo "Build failed; full log at $OUT_DIR/build.log" >&2
  exit $status
fi

overall=0
while IFS=$'\t' read -r slug udid model <&3; do
  echo "==> $model ($slug)"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl erase "$udid"

  result="$OUT_DIR/results/$slug.xcresult"
  rm -rf "$result"
  set +e
  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$ONLY_TESTING" \
    -parallel-testing-enabled NO \
    -resultBundlePath "$result" \
    > "$OUT_DIR/results/$slug.log" 2>&1
  status=$?
  set -e
  grep -E "error:|failed|passed|Executed" "$OUT_DIR/results/$slug.log" | tail -40 || true
  [[ $status -eq 0 ]] || overall=1

  python3 "$HERE/make_report.py" collect \
    --xcresult "$result" --slug "$slug" --device "$model" --out "$OUT_DIR/devices/$slug"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
done 3< "$OUT_DIR/devices.tsv"

python3 "$HERE/make_report.py" render --devices "$OUT_DIR/devices" --out "$OUT_DIR/report"
echo "==> Report: $OUT_DIR/report/index.html"
exit $overall
