#!/bin/sh
#
# Automatically build videoLat, current version.
# Run in a source directory
set -ex
#
# Setup directory
#
rm -rf thirdParty/installed-iossim
mkdir thirdParty/installed-iossim
INST=`(cd thirdParty/installed-iossim ; pwd)`
XCODEDEV=/Applications/Xcode.app/Contents/Developer
IOSVERSION=12.1
PATH=$INST/bin:$XCODEDEV/Platforms/iPhoneSimulator.platform/Developer/usr/bin:$XCODEDEV/usr/bin:$PATH
CFLAGS="-arch x86_64 -arch i386 -isysroot $XCODEDEV/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IOSVERSION.sdk -miphoneos-version-min=7.0"
PKG_CONFIG_LIBDIR=$INST/lib/pkgconfig

#
# Check for libpng15
#
if test -f thirdParty/libpng-1.6.*/configure; then
	echo libpng 1.6 sources found, building local copy
	(
		cd thirdParty/libpng-1.6.*
		./configure \
			--host=x86_64 \
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
	echo libpng 1.6 should be slurped for iPhone development
	exit 1
else
	echo libpng 1.6 installed.
	echo Please download from http://sourceforge.net/projects/libpng/files/libpng15/
	echo Then unpack into thirdParty/libpng-1.6.* and re-run this script.
	exit 1
fi

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
