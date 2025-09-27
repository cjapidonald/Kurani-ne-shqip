#!/usr/bin/env bash
set -euo pipefail

SCHEME=${SCHEME:-Kurani}
DESTINATION=${DESTINATION:-"platform=iOS Simulator,name=iPhone 15"}
DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-"$(pwd)/Build/DerivedData"}
RESULT_BUNDLE_PATH=${RESULT_BUNDLE_PATH:-"$(pwd)/Build/ci-tests.xcresult"}

xcodebuild \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build-for-testing

xcodebuild \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  test-without-building
