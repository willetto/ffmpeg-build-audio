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

# Smoke test: encode a 1-second 440 Hz sine wave to MP3 and verify the output is valid.
SMOKE_DIR=$(mktemp -d)
trap 'rm -rf "$SMOKE_DIR"' EXIT

SMOKE_MP3="$SMOKE_DIR/test.mp3"
if ! "$FFMPEG_BIN" -f lavfi -i "sine=frequency=440:duration=1" \
    -c:a libmp3lame -q:a 9 "$SMOKE_MP3" -y -loglevel error; then
  echo "libmp3lame MP3 encode smoke test FAILED" >&2
  exit 1
fi

if [ ! -s "$SMOKE_MP3" ]; then
  echo "MP3 output file is empty or missing" >&2
  exit 1
fi

printf "libmp3lame MP3 encode smoke test passed (%s bytes)\n" "$(wc -c < "$SMOKE_MP3" | tr -d ' ')"
