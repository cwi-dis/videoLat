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
# Build videoLat
#
echo Nothing more for now...
exit 1
xcodebuild -project videoLat-ios.xcodeproj
#
# All done
#
echo Your application should be waiting for you in `pwd`/build/Release
