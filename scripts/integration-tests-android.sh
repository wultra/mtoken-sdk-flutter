#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# list available Emulators
~/Library/Android/sdk/emulator/emulator -list-avds

# get the first available Emulator ID
EMULATOR_ID=$(~/Library/Android/sdk/emulator/emulator -list-avds | tail -n 1)

echo "Booting Android Emulator with ID: $EMULATOR_ID"

# open the Emulator app and boot the emulator
~/Library/Android/sdk/emulator/emulator -avd "$EMULATOR_ID" -netdelay none -netspeed full -qt-hide-window -grpc-use-token &
adb wait-for-device

DEVICE_ID=$( adb devices | awk 'NR>1 && $2=="device" {print $1}' )

pushd "$SCRIPT_FOLDER/../example"
# pushd "android"
# ./gradlew assemble # build to shave some time off the test run
# popd
flutter test -d "$DEVICE_ID" -r expanded integration_test/integration_test.dart --ignore-timeouts
popd