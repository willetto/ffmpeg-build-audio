#!/usr/bin/env bash

set -eux

cd $(dirname $0)
BASE_DIR=$(pwd)

source common.sh

# If you want to use the upstream git repository instead of the release tarball,
# set USE_GIT=1 in the environment. This ensures we pull source directly from
# https://git.ffmpeg.org/ffmpeg.git instead of relying on a local tarball.
USE_GIT=${USE_GIT:-0}

if [ "$USE_GIT" = "0" ] && [ ! -e $FFMPEG_TARBALL ]
then
	curl -s -L -O $FFMPEG_TARBALL_URL
fi

LAME_VERSION=3.100
LAME_TARBALL=lame-$LAME_VERSION.tar.gz
LAME_TARBALL_URL=https://sourceforge.net/projects/lame/files/lame/$LAME_VERSION/$LAME_TARBALL

if [ ! -e $LAME_TARBALL ]
then
	curl -s -L -O $LAME_TARBALL_URL
fi

: ${TARGET?}

case $TARGET in
    x86_64-*)
        ARCH="x86_64"
        ;;
    arm64-*)
        ARCH="arm64"
        ;;
    *)
        echo "Unknown target: $TARGET"
        exit 1
        ;;
esac

# Extract macOS deployment version from TARGET (e.g. "x86_64-apple-macos10.9" -> "10.9")
MACOSX_VER=$(echo "$TARGET" | sed -E 's/.*macos//')
MACOSX_MIN_FLAG="-mmacosx-version-min=$MACOSX_VER"

OUTPUT_DIR=artifacts/ffmpeg-$FFMPEG_VERSION-audio-$TARGET

BUILD_DIR=$BASE_DIR/$(mktemp -d build.XXXXXXXX)
trap 'rm -rf $BUILD_DIR' EXIT

# Prepare FFmpeg source: either clone from upstream git (recommended for CI/git-source
# workflows) or extract the release tarball shipped with the repo.
if [ "$USE_GIT" = "1" ]; then
    git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git $BUILD_DIR/ffmpeg-src || git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git $BUILD_DIR/ffmpeg-src
    cd $BUILD_DIR/ffmpeg-src
    # Try to check out the matching release tag (n8.0) if available; otherwise stay on HEAD.
    git checkout "n$FFMPEG_VERSION" || true
else
    cd $BUILD_DIR
    tar --strip-components=1 -xf $BASE_DIR/$FFMPEG_TARBALL
fi

LAME_PREFIX=$BUILD_DIR/lame-install
LAME_BUILD_DIR=$BUILD_DIR/lame-build

mkdir -p $LAME_BUILD_DIR
tar --strip-components=1 -xf $BASE_DIR/$LAME_TARBALL -C $LAME_BUILD_DIR

pushd $LAME_BUILD_DIR
# Use explicit arch and macOS deployment target so we build LAME for the correct target
# even when running on an Apple Silicon (arm64) runner cross-compiling x86_64.
export CFLAGS="-arch $ARCH $MACOSX_MIN_FLAG"
export LDFLAGS="-arch $ARCH $MACOSX_MIN_FLAG"
./configure \
    --prefix="$LAME_PREFIX" \
    --host="$ARCH-apple-darwin" \
    CC="/usr/bin/clang" \
    --disable-shared \
    --enable-static \
    --disable-frontend
make -j$(sysctl -n hw.ncpu || echo 2)
make install
popd

# Configure FFmpeg to use our LAME build and to compile for the requested target.
FFMPEG_CONFIGURE_FLAGS+=(
    --cc="/usr/bin/clang"
    --prefix=$BASE_DIR/$OUTPUT_DIR
    --enable-cross-compile
    --target-os=darwin
    --arch=$ARCH
    --extra-ldflags="$LDFLAGS -L$LAME_PREFIX/lib"
    --extra-cflags="$CFLAGS -I$LAME_PREFIX/include"
    --enable-runtime-cpudetect
)

# Run configure from the FFmpeg source directory (works for both git and tarball flows).
./configure "${FFMPEG_CONFIGURE_FLAGS[@]}" || (cat ffbuild/config.log && exit 1)

# config.h on macOS can report HAVE_MACH_MACH_TIME_H, which causes build issues in CI;
# keep the previous workaround in place.
perl -pi -e 's{HAVE_MACH_MACH_TIME_H 1}{HAVE_MACH_MACH_TIME_H 0}' config.h

make V=1 -j$(sysctl -n hw.ncpu || echo 2)
make install

chown -R $(stat -f '%u:%g' $BASE_DIR) $BASE_DIR/$OUTPUT_DIR
