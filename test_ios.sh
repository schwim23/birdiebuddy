#!/bin/bash
set -euo pipefail

SCHEME="BirdieBuddy"
DESTINATION="platform=iOS Simulator,name=iPhone 16"

echo "Building and testing $SCHEME..."
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -resultBundlePath TestResults.xcresult \
  2>&1 | tail -50
