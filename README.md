Static audio-only FFmpeg builds
===============================================

This repository is a **fork of** [acoustid/ffmpeg-build](https://github.com/acoustid/ffmpeg-build). It keeps the same lightweight, audio‑only FFmpeg configuration but **adds the encoders/muxers needed for audio trimming/export**.

## What’s different vs upstream

- **Encoders enabled:** `pcm_s16le`, `libmp3lame`
- **Muxers enabled:** `wav`, `mp3`
- Purpose: enable waveform generation and MP3 export for audio editor apps.

Upstream is decode‑only; this fork supports **encode + mux** for audio workflows.

## Releases / How to consume

All builds are published as GitHub release assets. To consume, download the asset that matches your target triple:

| Target triple | Asset name |
| --- | --- |
| `x86_64-pc-windows-msvc` | `ffmpeg-8.0-audio-x86_64-w64-mingw32.tar.gz` |
| `x86_64-unknown-linux-gnu` | `ffmpeg-8.0-audio-x86_64-linux-gnu.tar.gz` |
| `aarch64-unknown-linux-gnu` | `ffmpeg-8.0-audio-arm64-linux-gnu.tar.gz` |
| `x86_64-apple-darwin` | `ffmpeg-8.0-audio-x86_64-apple-macos10.9.tar.gz` |
| `aarch64-apple-darwin` | `ffmpeg-8.0-audio-arm64-apple-macos11.tar.gz` |

Example download (replace tag/version as needed):

```bash
TAG=v8.0-podcast-2
curl -L -o ffmpeg.tar.gz \
  https://github.com/willetto/ffmpeg-build-audio/releases/download/$TAG/ffmpeg-8.0-audio-x86_64-apple-macos10.9.tar.gz
```

## Supported platforms

- Linux
  - `x86_64-linux-gnu`
  - `arm64-linux-gnu`
- Windows
  - `x86_64-w64-mingw32`
- macOS
  - `x86_64-apple-macos10.9` (Intel, macOS 10.9+)
  - `arm64-apple-macos11` (Apple Silicon, macOS 11+)

## Credits

- Upstream build scripts: [acoustid/ffmpeg-build](https://github.com/acoustid/ffmpeg-build)
- FFmpeg: https://ffmpeg.org/
