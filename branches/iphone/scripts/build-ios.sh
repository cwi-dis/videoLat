#!/bin/sh
#
# Automatically build videoLat, current version.
# Run in a source directory
set -ex
#
# Setup directory
#
rm -rf thirdParty/installed-ios
mkdir thirdParty/installed-ios
INST=`(cd thirdParty/installed-ios ; pwd)`
XCODEDEV=/Applications/Xcode.app/Contents/Developer
IOSVERSION=8.2
PATH=$INST/bin:$XCODEDEV/Platforms/iPhoneOS.platform/Developer/usr/bin:$XCODEDEV/usr/bin:$PATH
CFLAGS="-arch armv7 -arch arm64 -isysroot $XCODEDEV/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOSVERSION.sdk"
PKG_CONFIG_LIBDIR=$INST/lib/pkgconfig

#
# Check for libpng15
#
if test -f thirdParty/libpng-1.5.18/configure; then
	echo libpng 1.5 sources found, building local copy
	(
		cd thirdParty/libpng-1.5.18
		./configure \
			--host=armv7 \
			--prefix=$INST \
			--disable-arm-neon \
			CFLAGS="$CFLAGS" \
			CXXFLAGS="$CFLAGS" \
			LDFLAGS="$CFLAGS"
		make clean
		make
		make install
	)
elif (libpng15-config --version > /dev/null 2>&1); then
	echo libpng 1.5 should be slurped for iPhone development
	exit 1
else
	echo libpng 1.5 not installed.
	echo Please download from http://sourceforge.net/projects/libpng/files/libpng15/
	echo Then unpack into thirdParty/libpng-1.5.18 and re-run this script.
	exit 1
fi

#
# build zbar
#
(
	cd thirdParty/zbar-0.10-src
	./configure \
			--host=armv7 \
			--disable-dependency-tracking \
			--disable-video \
			--without-gtk \
			--without-qt \
			--without-xv \
			--without-imagemagick \
			--without-x \
			--without-xshm \
			--without-python \
			--prefix=$INST \
			CFLAGS="$CFLAGS" \
			CXXFLAGS="$CFLAGS" \
			LDFLAGS="$CFLAGS"
	make clean
	make
	make install
)
#
# Build zint
#
(
	cd thirdParty/zint-2.4.3
	make clean
	make prefix=$INST CFLAGS="$CFLAGS"
	make install prefix=$INST
)
#
# Build videoLat
#
echo Nothing more for now...
exit 1
xcodebuild -project videoLat-ios.xcodeproj
#
# All done
#
echo Your application should be waiting for you in `pwd`/build/Release
