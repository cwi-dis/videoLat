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
SCRIPTDIR=`(cd scripts ; pwd)`
INST=`(cd thirdParty/installed-ios ; pwd)`
XCODEDEV=/Applications/Xcode.app/Contents/Developer
IOSVERSION=12.1
PATH=$INST/bin:$XCODEDEV/Platforms/iPhoneOS.platform/Developer/usr/bin:$XCODEDEV/usr/bin:$PATH
CFLAGS="-arch arm64 -isysroot $XCODEDEV/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IOSVERSION.sdk"
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
