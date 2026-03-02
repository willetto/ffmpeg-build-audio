#!/usr/bin/env bash

set -euo pipefail

# Verify that built ffmpeg binaries do not link to /opt/homebrew or /usr/local,
# which exist on build machines but not on end-user Macs (causes "can't open" / Error 163).

ARTIFACTS_DIR="${1:-artifacts}"
cd "$(dirname "$0")/.."

FAILED=0

for BIN in "$ARTIFACTS_DIR"/*/bin/ffmpeg; do
    if [ ! -f "$BIN" ]; then
        echo "::warning::No ffmpeg binaries found under $ARTIFACTS_DIR/*/bin/ffmpeg" >&2
        exit 1
    fi

    OTOOL_OUT=$(otool -L "$BIN")
    BAD_PATHS=$(echo "$OTOOL_OUT" | awk '/^\t/ {print $1}' | grep -E '^/(opt/homebrew|usr/local)/' || true)

    if [ -n "$BAD_PATHS" ]; then
        echo "::error::Binary $BIN links to external dylibs not present on end-user Macs" >&2
        echo "Offending paths:" >&2
        echo "$BAD_PATHS" | sed 's/^/  /' >&2
        echo "" >&2
        echo "Full otool -L output for $BIN:" >&2
        echo "$OTOOL_OUT" | sed 's/^/  /' >&2
        echo "" >&2
        echo "Hint: Unset PKG_CONFIG_PATH/CPPFLAGS/LDFLAGS/LIBRARY_PATH; set PKG_CONFIG_LIBDIR=/var/empty; restrict PATH to exclude /opt/homebrew/bin; use --disable-sdl2 --disable-libxcb" >&2
        FAILED=1
    fi
done

if [ "$FAILED" -eq 1 ]; then
    exit 1
fi

echo "All ffmpeg binaries have no external dylib dependencies (OK)"
