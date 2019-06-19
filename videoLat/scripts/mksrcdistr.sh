#!/bin/sh
#
# Create a source distribution.
# The subversion source is cloned into a new, empty, directory and a
# tarbal is created from that.
if [ ! -f videoLat-macos.xcodeproj/project.pbxproj ]; then
	echo Please run in videoLat source directory
	exit 1
fi
set -x
#
# Find the parameters
#
VIDEOLAT_VERSION=`sed -ne 's/.*VIDEOLAT_VERSION = \([^"].*\);/\1/p' videoLat-macos.xcodeproj/project.pbxproj | head -1`
VIDEOLAT_IOS_VERSION=`sed -ne 's/.*VIDEOLAT_VERSION = \([^"].*\);/\1/p' videoLat-macos.xcodeproj/project.pbxproj | head -1`
if test "$VIDEOLAT_VERSION" != "$VIDEOLAT_IOS_VERSION"; then
	echo Different versions for MacOS and iOS:
	echo MacOS: $VIDEOLAT_VERSION
	echo iOS: $VIDEOLAT_IOS_VERSION
	exit 1
fi
DIRNAME=videoLat-$VIDEOLAT_VERSION
BRANCHNAME=`git rev-parse --abbrev-ref HEAD`
#
# Create the tarball
#
rm -rf build/_src
mkdir -p build/_src/$DIRNAME
git archive $BRANCHNAME . | tar -x -C build/_src/$DIRNAME
cd build/_src
tar cfz ../$DIRNAME-src.tgz $DIRNAME
rm -rf $DIRNAME
#
# Test the build
#
tar xfv ../$DIRNAME-src.tgz
cd $DIRNAME
xcodebuild -project videoLat-macos.xcodeproj -target videoLat -configuration Release build
xcodebuild -project videoLat-iOS.xcodeproj -target videoLat -configuration Release build

