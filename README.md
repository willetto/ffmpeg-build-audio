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

## Build notes (macOS distribution)

The macOS FFmpeg binary must **not** link to `/opt/homebrew` or `/usr/local`. Those paths exist on build machines but not on end-user Macs; linking to them causes "The application can't be opened" / Error 163 when the binary is bundled (e.g. in a Tauri app).

**What we do:** In CI we (1) unset `PKG_CONFIG_PATH`, `CPPFLAGS`, `LDFLAGS`, `LIBRARY_PATH`; (2) set `PKG_CONFIG_LIBDIR=/var/empty` so pkg-config finds no Homebrew packages; (3) restrict `PATH` to exclude `/opt/homebrew/bin` (so `sdl2-config` and `pkg-config` are not used) while keeping `nasm`; (4) use `--disable-sdl2` and `--disable-libxcb` in `FFMPEG_CONFIGURE_FLAGS`.

**How to verify:** Run `./scripts/verify-no-external-dylibs.sh` after building, or inspect manually:

```bash
otool -L artifacts/ffmpeg-*/bin/ffmpeg
```

Ensure no paths contain `/opt/homebrew` or `/usr/local`. Allowed paths include `/usr/lib/*` and `/System/Library/*`.

## Credits

- Upstream build scripts: [acoustid/ffmpeg-build](https://github.com/acoustid/ffmpeg-build)
- FFmpeg: https://ffmpeg.org/
