#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Running tests on Android device with ID: $DEVICE_ID"

pushd "$SCRIPT_FOLDER/../example"
flutter test -r expanded integration_test/integration_test.dart --ignore-timeouts
popd