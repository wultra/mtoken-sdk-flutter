#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# kill the simulator app if it's running
killall -9 Simulator

# get the first available iOS Simulator ID
SIM_ID=$(xcrun simctl list devices available | grep 'iPhone' | head -n 1 | grep -oE '[A-F0-9-]{36}')

echo "Booting iOS Simulator with ID: $SIM_ID"

# open the Simulator app and boot the simulator
open -a Simulator
xcrun simctl boot "$SIM_ID"

# we dont need to wait for the simulator to be fully booted, just run the tests (the compilation takes time anyway)

pushd "$SCRIPT_FOLDER/../example"
pushd "ios"
pod install # install pods to shave some time off the test run
popd
flutter test -d "$SIM_ID" -r expanded integration_test/integration_test.dart
popd