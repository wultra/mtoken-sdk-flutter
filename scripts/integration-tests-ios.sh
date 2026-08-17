#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Pass --verbose to include SDK and IntegrationHelper HTTP logs.
TEST_LOGGING=false
if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [--verbose]" >&2
  exit 2
fi

case "${1:-}" in
  "") ;;
  --verbose) TEST_LOGGING=true ;;
  *)
    echo "Usage: $0 [--verbose]" >&2
    exit 2
    ;;
esac

# list available iOS Simulators
xcrun simctl list devices available

# get the first available iOS Simulator ID
SIM_ID=$(xcrun simctl list devices available | grep 'iPhone' | head -n 1 | grep -oE '[A-F0-9-]{36}')

echo "Booting iOS Simulator with ID: $SIM_ID"

# open the Simulator app and boot the simulator
open -a Simulator
xcrun simctl boot "$SIM_ID"

# wait until the simulator is actually booted/ready (to give more deterministic logs)
xcrun simctl bootstatus "$SIM_ID" -b

pushd "$SCRIPT_FOLDER/../example"

flutter build ios --config-only --no-pub --dart-define=INTEGRATION_TEST_LOGGING="$TEST_LOGGING" integration_test/integration_test.dart
xcodebuild build-for-testing -quiet -workspace ios/Runner.xcworkspace -scheme Runner -destination "platform=iOS Simulator,id=$SIM_ID" -parallel-testing-enabled NO
xcodebuild test-without-building -workspace ios/Runner.xcworkspace -scheme Runner -destination "platform=iOS Simulator,id=$SIM_ID" -parallel-testing-enabled NO

popd
