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

OUTPUT_DIR=artifacts/ffmpeg-$FFMPEG_VERSION-audio-$ARCH-linux-gnu

case $ARCH in
    x86_64)
        ;;
    i686)
        FFMPEG_CONFIGURE_FLAGS+=(--cc="gcc -m32")
        ;;
    arm64)
        FFMPEG_CONFIGURE_FLAGS+=(
            --enable-cross-compile
            --cross-prefix=aarch64-linux-gnu-
            --target-os=linux
            --arch=aarch64
        )
        BUILD_LAME_FOR_CROSS=1
        ;;
    arm*)
        FFMPEG_CONFIGURE_FLAGS+=(
            --enable-cross-compile
            --cross-prefix=arm-linux-gnueabihf-
            --target-os=linux
            --arch=arm
        )
        case $ARCH in
            armv7-a)
                FFMPEG_CONFIGURE_FLAGS+=(
                    --cpu=armv7-a
                )
                ;;
            armv8-a)
                FFMPEG_CONFIGURE_FLAGS+=(
                    --cpu=armv8-a
                )
                ;;
            armhf-rpi2)
                FFMPEG_CONFIGURE_FLAGS+=(
                    --cpu=cortex-a7
                    --extra-cflags='-fPIC -mcpu=cortex-a7 -mfloat-abi=hard -mfpu=neon-vfpv4 -mvectorize-with-neon-quad'
                )
                ;;
            armhf-rpi3)
                FFMPEG_CONFIGURE_FLAGS+=(
                    --cpu=cortex-a53
                    --extra-cflags='-fPIC -mcpu=cortex-a53 -mfloat-abi=hard -mfpu=neon-fp-armv8 -mvectorize-with-neon-quad'
                )
                ;;
        esac
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        exit 1
        ;;
esac

BUILD_DIR=$(mktemp -d -p $(pwd) build.XXXXXXXX)
trap 'rm -rf $BUILD_DIR' EXIT

cd $BUILD_DIR

if [ "${BUILD_LAME_FOR_CROSS:-0}" = "1" ]; then
	LAME_PREFIX=$BUILD_DIR/lame-install
	LAME_BUILD_DIR=$BUILD_DIR/lame-build
	mkdir -p $LAME_BUILD_DIR
	tar --strip-components=1 -xf $BASE_DIR/$LAME_TARBALL -C $LAME_BUILD_DIR
	pushd $LAME_BUILD_DIR
	./configure \
		--prefix="$LAME_PREFIX" \
		--host=aarch64-linux-gnu \
		CC=aarch64-linux-gnu-gcc \
		--disable-shared \
		--enable-static \
		--disable-frontend
	make -j$(nproc 2>/dev/null || echo 2)
	make install
	popd
	FFMPEG_CONFIGURE_FLAGS+=(
		--extra-cflags="-I$LAME_PREFIX/include"
		--extra-ldflags="-L$LAME_PREFIX/lib"
	)
fi

tar --strip-components=1 -xf $BASE_DIR/$FFMPEG_TARBALL -C $BUILD_DIR

./configure "${FFMPEG_CONFIGURE_FLAGS[@]}" || (cat ffbuild/config.log && exit 1)

make
make install

chown $(stat -c '%u:%g' $BASE_DIR) -R $BASE_DIR/$OUTPUT_DIR
