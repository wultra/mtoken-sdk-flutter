#!/bin/bash

killall -9 Simulator

SIM_ID=$(xcrun simctl list devices available | grep 'iPhone' | head -n 1 | grep -oE '[A-F0-9-]{36}')

echo "Booting iOS Simulator with ID: $SIM_ID"

open -a Simulator
xcrun simctl boot "$SIM_ID"

while [[ "$(xcrun simctl list devices | grep "$SIM_ID")" != *"Booted"* ]]; do
    echo "Waiting for simulator to boot..."
    sleep 2
done

echo "Simulator is now booted."