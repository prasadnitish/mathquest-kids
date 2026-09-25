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
# Release: launches fast enough for XCUITest's launch timeout on slow CI machines,
# and matches what testers get from TestFlight.
CONFIGURATION="${CONFIGURATION:-Release}"
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
  -configuration "$CONFIGURATION" \
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

APP="$(find "$DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator" -maxdepth 1 -name '*.app' ! -name '*Runner.app' | head -1)"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")"

# Prints the useful part of a failed run: test errors plus any app crash report.
show_failure_details() {
  local log="$1"
  echo "---- failure details ----"
  grep -E "error:|Crash|crashed|Timed out|Failed to|failed \(" "$log" | head -60 || true
  local crash
  crash="$(ls -t "$HOME"/Library/Logs/DiagnosticReports/*Sprout* 2>/dev/null | head -1 || true)"
  if [[ -n "$crash" ]]; then
    echo "---- newest crash report: $crash ----"
    head -c 4000 "$crash"
    echo
  fi
  echo "-------------------------"
}

overall=0
while IFS=$'\t' read -r slug udid model <&3; do
  echo "==> $model ($slug)"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl erase "$udid"
  # Boot fully (home screen ready) and pay the first-launch cost before XCUITest
  # starts timing launches; "-ui-test" keeps the warm-up from saving a profile.
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl install "$udid" "$APP"
  xcrun simctl launch "$udid" "$BUNDLE_ID" -ui-test >/dev/null || true
  sleep 20
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true

  result="$OUT_DIR/results/$slug.xcresult"
  rm -rf "$result"
  set +e
  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$ONLY_TESTING" \
    -parallel-testing-enabled NO \
    -resultBundlePath "$result" \
    > "$OUT_DIR/results/$slug.log" 2>&1
  status=$?
  set -e
  grep -E "Test Case .*(passed|failed)|Executed" "$OUT_DIR/results/$slug.log" | tail -12 || true
  if [[ $status -ne 0 ]]; then
    overall=1
    show_failure_details "$OUT_DIR/results/$slug.log"
  fi

  python3 "$HERE/make_report.py" collect \
    --xcresult "$result" --slug "$slug" --device "$model" --out "$OUT_DIR/devices/$slug"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
done 3< "$OUT_DIR/devices.tsv"

python3 "$HERE/make_report.py" render --devices "$OUT_DIR/devices" --out "$OUT_DIR/report"
echo "==> Report: $OUT_DIR/report/index.html"
exit $overall
