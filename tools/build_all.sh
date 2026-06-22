#!/bin/bash

set -eu -o pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

PROJECT_ROOT="${SCRIPT_DIR}/../"
BUILD_DIR="${PROJECT_ROOT}/_build"

if [ ! -d "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT/src/boards/" ]; then
    echo "Project root error: $PROJECT_ROOT"
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

if which parallel >/dev/null 2>&1; then
    find "${PROJECT_ROOT}/src/boards" -mindepth 1 -maxdepth 1 -type d | parallel make -j1 'BOARD={/}' all
else
    for BOARD in "${PROJECT_ROOT}"/src/boards/*/; do
        BOARD=$(basename "${BOARD}")
        echo "Building for ${BOARD}"
        make -j1 BOARD="${BOARD}" all || continue
    done
fi

BOARD_COUNT=$(find "${PROJECT_ROOT}"/src/boards/ -mindepth 1 -maxdepth 1 -type d | wc -l)
BUILT_BOOTLOADERS=$(find "$BUILD_DIR" -name '*_s[0-9][0-9][0-9]_*.hex' | wc -l)

# once in a blue moon make fails due to concurrency problems so we have to check
if [[ "$BOARD_COUNT" != "$BUILT_BOOTLOADERS" ]]; then
    echo "Error: not all targets have respective binaries built!" 1>&2
    echo "$BOARD_COUNT boards defined" 1>&2
    echo "$BUILT_BOOTLOADERS bootloader images built" 1>&2
    exit 1
fi

echo "Build successful"
