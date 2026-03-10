#!/usr/bin/env bash
set -euo pipefail

PROJECT="/Users/nitish/VS Code Projects/tpm-portfolio/mathquest-kids/MathQuestKids.xcodeproj"
SCHEME="MathQuestKids"
DESTINATION="platform=iOS Simulator,name=iPad (10th generation)"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode and xcode-select it first."
  exit 1
fi

echo "Running unit and integration tests..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -only-testing:MathQuestKidsTests test

echo "Running UI tests..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$DESTINATION" -only-testing:MathQuestKidsUITests test

echo "QA run completed successfully."
