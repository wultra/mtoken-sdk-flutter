#!/bin/bash

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
flutter test integration_test/integration_test.dart -d "$SIM_ID"
popd