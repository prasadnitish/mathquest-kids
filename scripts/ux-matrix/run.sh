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
TEST_CLASS="MathQuestKidsUITests/LayoutMatrixUITests"
# Each test runs on a freshly erased and booted simulator, so one launch hiccup or crash
# can't take the rest of the device's results down with it. Override with TESTS="...".
TESTS="${TESTS:-testQuestCheckLayouts testCoreFlowLayouts testQuestionFormatLayouts1 testQuestionFormatLayouts2 testQuestionFormatLayouts3 testQuestionFormatLayouts4}"
# Release: launches fast enough for XCUITest's launch timeout on slow CI machines,
# and matches what testers get from TestFlight. The build only includes the UI tests
# (and keeps testability on) because the unit tests need `@testable import`.
CONFIGURATION="${CONFIGURATION:-Release}"
HERE="$ROOT/scripts/ux-matrix"

mkdir -p "$OUT_DIR/results" "$OUT_DIR/devices"

echo "==> Picking simulators"
python3 "$HERE/pick_simulators.py" "$@" > "$OUT_DIR/devices.tsv"
if [[ ! -s "$OUT_DIR/devices.tsv" ]]; then
  echo "No simulators matched." >&2
  exit 1
fi

echo "==> Building for testing ($(xcodebuild -version | sed -n 1p))"
set +e
xcodebuild build-for-testing \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$DERIVED_DATA" \
  -only-testing:"$TEST_CLASS" \
  CODE_SIGNING_ALLOWED=NO \
  ENABLE_TESTABILITY=YES \
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

# Fresh state for every test: erased, fully booted (home screen ready), app installed and
# launched once so first-launch costs don't count against XCUITest's launch timeout.
# "-ui-test" keeps the warm-up from saving a profile.
prepare_simulator() {
  local udid="$1"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl erase "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl install "$udid" "$APP"
  xcrun simctl launch "$udid" "$BUNDLE_ID" -ui-test >/dev/null || true
  sleep 20
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
}

run_test() {
  local udid="$1" test="$2" result="$3" log="$4"
  rm -rf "$result"
  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$TEST_CLASS/$test" \
    -parallel-testing-enabled NO \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 2400 \
    -maximum-test-execution-time-allowance 2700 \
    -resultBundlePath "$result" \
    > "$log" 2>&1
}

# XCUITest occasionally fails to start or stop the app on busy CI simulators. Those errors
# (and only those) get one retry on a fresh simulator; layout failures are never retried.
LAUNCH_ERRORS="Failed to terminate|Failed to launch|Timed out while launching|Failed to get background assertion"

overall=0
while IFS=$'\t' read -r slug udid model <&3; do
  echo "==> $model ($slug)"
  results=()
  for test in $TESTS; do
    result="$OUT_DIR/results/$slug-$test.xcresult"
    log="$OUT_DIR/results/$slug-$test.log"

    prepare_simulator "$udid"
    set +e
    run_test "$udid" "$test" "$result" "$log"
    status=$?
    if [[ $status -ne 0 ]] && grep -qE "$LAUNCH_ERRORS" "$log"; then
      echo "   $test: XCUITest couldn't start or stop the app; retrying once on a fresh simulator"
      mv "$log" "${log%.log}.attempt1.log"
      prepare_simulator "$udid"
      run_test "$udid" "$test" "$result" "$log"
      status=$?
    fi
    set -e

    grep -E "Test Case .*(passed|failed)" "$log" | tail -3 || true
    # The test prints LXDIAG lines when it can't scroll something into view.
    grep -F "LXDIAG" "$log" | head -40 || true
    if [[ $status -ne 0 ]]; then
      overall=1
      show_failure_details "$log"
    fi
    results+=(--xcresult "$result")
  done

  python3 "$HERE/make_report.py" collect "${results[@]}" \
    --slug "$slug" --device "$model" --out "$OUT_DIR/devices/$slug"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
done 3< "$OUT_DIR/devices.tsv"

python3 "$HERE/make_report.py" render --devices "$OUT_DIR/devices" --out "$OUT_DIR/report"
echo "==> Report: $OUT_DIR/report/index.html"
exit $overall
