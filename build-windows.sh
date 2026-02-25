#!/usr/bin/env bash

set -eu

cd $(dirname $0)
BASE_DIR=$(pwd)

source common.sh

if [ ! -e $FFMPEG_TARBALL ]
then
	curl -s -L -O $FFMPEG_TARBALL_URL
fi

LAME_VERSION=3.100
LAME_TARBALL=lame-$LAME_VERSION.tar.gz
LAME_TARBALL_URL=https://sourceforge.net/projects/lame/files/lame/$LAME_VERSION/$LAME_TARBALL
if [ ! -e $LAME_TARBALL ]; then
	curl -s -L -O $LAME_TARBALL_URL
fi

: ${ARCH?}

OUTPUT_DIR=artifacts/ffmpeg-$FFMPEG_VERSION-audio-$ARCH-w64-mingw32

BUILD_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $BUILD_DIR' EXIT

cd $BUILD_DIR

LAME_PREFIX=$BUILD_DIR/lame-install
LAME_BUILD_DIR=$BUILD_DIR/lame-build
mkdir -p $LAME_BUILD_DIR
tar --strip-components=1 -xf $BASE_DIR/$LAME_TARBALL -C $LAME_BUILD_DIR
pushd $LAME_BUILD_DIR
curl -fsSL -o config.sub "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub"
curl -fsSL -o config.guess "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess"
./configure \
	--prefix="$LAME_PREFIX" \
	--host=$ARCH-w64-mingw32 \
	CC=$ARCH-w64-mingw32-gcc \
	--disable-shared \
	--enable-static \
	--disable-frontend
make -j$(nproc 2>/dev/null || echo 2)
make install
popd

tar --strip-components=1 -xf $BASE_DIR/$FFMPEG_TARBALL

FFMPEG_CONFIGURE_FLAGS+=(
    --prefix=$BASE_DIR/$OUTPUT_DIR
    --extra-cflags="-static -static-libgcc -static-libstdc++ -I$LAME_PREFIX/include"
    --extra-ldflags="-static -static-libgcc -static-libstdc++ -L$LAME_PREFIX/lib"
    --target-os=mingw32
    --arch=$ARCH
    --cross-prefix=$ARCH-w64-mingw32-
)

./configure "${FFMPEG_CONFIGURE_FLAGS[@]}"
make
make install

chown $(stat -c '%u:%g' $BASE_DIR) -R $BASE_DIR/$OUTPUT_DIR
