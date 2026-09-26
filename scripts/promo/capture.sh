#!/usr/bin/env bash
# Films the promo scenes (MathQuestKidsUITests/PromoCaptureUITests) on iOS simulators: the
# screen is recorded while each scene's UI test runs, and the test's step and tap log is saved
# next to the video with times measured from the video's first frame.
#
# Usage:
#   scripts/promo/capture.sh                               # iphone-standard ipad-standard
#   scripts/promo/capture.sh ipad-large                    # device classes from pick_simulators.py
#   SCENES="testSceneThemes" scripts/promo/capture.sh      # just some scenes
#
# Output, per device class, in $OUT_DIR/<class>/:
#   <scene>.mp4    30 fps H.264, longest side 1920 px (needs ffmpeg; otherwise the raw recording)
#   <scene>.log    "MARK <name> <seconds>" and "TAP <x> <y> <seconds>" (x, y as screen fractions)
#   <scene>-<mark>.jpg  a still at each mark, for picking shots without opening the videos
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/build/promo}"
DERIVED_DATA="${DERIVED_DATA:-$OUT_DIR/DerivedData}"
PROJECT="$ROOT/MathQuestKids.xcodeproj"
SCHEME="MathQuestKids"
TEST_CLASS="MathQuestKidsUITests/PromoCaptureUITests"
SCENES="${SCENES:-testSceneThemes testSceneColumnAddition testSceneColumnSubtraction testSceneTeenPlaceValue testSceneSpatial testSceneStickersAndTrail testSceneParentDashboard}"
# Release, like the layout matrix: it launches quickly enough on slow CI machines, and it's
# what testers get.
CONFIGURATION="${CONFIGURATION:-Release}"
CLASSES=("$@")
if [[ ${#CLASSES[@]} -eq 0 ]]; then
  CLASSES=(iphone-standard ipad-standard)
fi

mkdir -p "$OUT_DIR"

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
  exit $status
fi

APP="$(find "$DERIVED_DATA/Build/Products/$CONFIGURATION-iphonesimulator" -maxdepth 1 -name '*.app' ! -name '*Runner.app' | head -1)"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")"

# The software keyboard should show when the parent types the PIN.
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false || true

now() { python3 -c 'import time; print(f"{time.time():.3f}")'; }

prepare_simulator() {
  local udid="$1"
  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl erase "$udid"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl ui "$udid" appearance light || true
  # The classic marketing status bar: 9:41, full signal, full battery.
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
  xcrun simctl install "$udid" "$APP"
  # Warm up once so first-launch costs don't land in the footage or the launch timeout.
  xcrun simctl launch "$udid" "$BUNDLE_ID" -ui-test >/dev/null || true
  sleep 15
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
}

# Turns the test's PROMO- lines into times from the start of the video.
write_scene_log() {
  local started="$1" xcodebuild_log="$2" out="$3"
  python3 - "$started" "$xcodebuild_log" > "$out" <<'PY'
import re, sys
start = float(sys.argv[1])
for line in open(sys.argv[2], errors="replace"):
    mark = re.search(r"PROMO-MARK (\S+) ([0-9.]+)", line)
    tap = re.search(r"PROMO-TAP ([0-9.]+) ([0-9.]+) ([0-9.]+)", line)
    if mark:
        print(f"MARK {mark.group(1)} {float(mark.group(2)) - start:.3f}")
    elif tap:
        print(f"TAP {tap.group(1)} {tap.group(2)} {float(tap.group(3)) - start:.3f}")
PY
}

film_scene() {
  local udid="$1" scene="$2" dir="$3"
  local raw="$dir/$scene.raw.mp4" rec_log="$dir/$scene.record.log" test_log="$dir/$scene.xcodebuild.log"
  rm -f "$raw" "$rec_log"

  xcrun simctl io "$udid" recordVideo --codec=h264 --force "$raw" > "$rec_log" 2>&1 &
  local recorder=$!
  local started=""
  for _ in $(seq 1 100); do
    if grep -q "Recording started" "$rec_log" 2>/dev/null; then
      started="$(now)"
      break
    fi
    sleep 0.1
  done
  if [[ -z "$started" ]]; then
    echo "   $scene: recorder didn't report a start; timing from now"
    started="$(now)"
  fi

  set +e
  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$TEST_CLASS/$scene" \
    -parallel-testing-enabled NO \
    > "$test_log" 2>&1
  local status=$?
  set -e

  sleep 1
  kill -INT "$recorder" 2>/dev/null || true
  wait "$recorder" 2>/dev/null || true

  write_scene_log "$started" "$test_log" "$dir/$scene.log"
  echo "   $scene: test exit $status, $(grep -c '^MARK' "$dir/$scene.log" || true) marks, $(grep -c '^TAP' "$dir/$scene.log" || true) taps"
  if [[ $status -ne 0 ]]; then
    grep -E "error:|failed|PROMO-MISSING" "$test_log" | head -20 || true
  fi

  if command -v ffmpeg >/dev/null && [[ -s "$raw" ]]; then
    ffmpeg -loglevel error -y -i "$raw" \
      -vf "fps=30,scale='if(gt(iw,ih),1920,-2)':'if(gt(iw,ih),-2,1920)':flags=lanczos,format=yuv420p" \
      -c:v libx264 -preset slow -crf 19 -movflags +faststart -an "$dir/$scene.mp4"
    rm -f "$raw"
    while read -r kind name seconds; do
      [[ "$kind" == "MARK" ]] || continue
      ffmpeg -loglevel error -y -ss "$(python3 -c "print(max(0, $seconds + 0.6))")" -i "$dir/$scene.mp4" \
        -frames:v 1 -vf "scale=-2:720" -q:v 4 "$dir/$scene-$name.jpg" || true
    done < "$dir/$scene.log"
  elif [[ -s "$raw" ]]; then
    mv "$raw" "$dir/$scene.mp4"
  fi
}

for class in "${CLASSES[@]}"; do
  line="$(python3 "$ROOT/scripts/ux-matrix/pick_simulators.py" "$class" | head -1)"
  udid="$(cut -f2 <<< "$line")"
  model="$(cut -f3 <<< "$line")"
  [[ -n "$udid" ]] || { echo "No simulator for $class" >&2; exit 1; }
  echo "==> $model ($class)"
  dir="$OUT_DIR/$class"
  mkdir -p "$dir"
  prepare_simulator "$udid"
  for scene in $SCENES; do
    film_scene "$udid" "$scene" "$dir"
  done
  xcrun simctl status_bar "$udid" clear || true
  xcrun simctl shutdown "$udid" || true
done
