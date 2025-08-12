#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# URL of the JavaScript prepare-release script in Wultra infrastructure repository
URL="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile-release/mobile-release/v1/prepare-release.js"

# Create a temporary file
TMP_FILE=$(mktemp)

# Ensure the temporary file is removed on exit
trap 'rm -f "$TMP_FILE"' EXIT

# Download the file
echo "Downloading prepare-release.js script from Wultra infrastructure repository..."
curl -fsSL "$URL" -o "$TMP_FILE"

# Run the file with Node.js in a root directory of the repository
COMMAND="node $TMP_FILE -p $SCRIPT_FOLDER/.." # --ignore-git-clean" 
if [ $# -ge 1 ]; then
  COMMAND="$COMMAND -v $1"
fi
echo "Executing command: $COMMAND"
eval "$COMMAND"