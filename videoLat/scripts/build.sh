#!/bin/sh
#
# Automatically build videoLat, current version.
# Run in a source directory
set -x
#
# Setup directory
#
rm -rf thirdParty/installed
mkdir thirdParty/installed
INST=`(cd thirdParty/installed ; pwd)`
PATH=$INST/bin:$PATH

#
# Build videoLat
#
xcodebuild -project videoLat.xcodeproj
#
# All done
#
echo Your application should be waiting for you in `pwd`/build/Release
