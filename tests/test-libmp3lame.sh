#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

source common.sh

: ${TARGET?}

OUTPUT_DIR="artifacts/ffmpeg-$FFMPEG_VERSION-audio-$TARGET"
FFMPEG_BIN="$OUTPUT_DIR/bin/ffmpeg"

if [ ! -x "$FFMPEG_BIN" ]; then
  echo "Expected ffmpeg binary at $FFMPEG_BIN" >&2
  exit 1
fi

if ! "$FFMPEG_BIN" -hide_banner -encoders | grep -q "libmp3lame"; then
  echo "libmp3lame encoder missing from $FFMPEG_BIN" >&2
  exit 1
fi

printf "libmp3lame encoder present in %s\n" "$FFMPEG_BIN"
