#!/bin/sh
#
# Create a source distribution.
# The subversion source is cloned into a new, empty, directory and a
# tarbal is created from that.
if [ ! -f videoLat.xcodeproj/project.pbxproj ]; then
	echo Please run in videoLat source directory
	exit 1
fi
set -x
#
# Find the parameters
#
SVNURL=`svn info | sed -ne 's/URL: //p'`
VIDEOLAT_VERSION=`sed -ne 's/.*VIDEOLAT_VERSION = \([^"].*\);/\1/p' videoLat.xcodeproj/project.pbxproj | head -1`
DIRNAME=videoLat-$VIDEOLAT_VERSION
#
# Create the tarball
#
rm -rf build/_src
mkdir -p build/_src
cd build/_src
svn co $SVNURL $DIRNAME
find $DIRNAME -name .svn -print | xargs rm -rf '{}' ';'
tar cfz ../$DIRNAME-src.tgz $DIRNAME
rm -rf $DIRNAME
#
# Test the build
#
tar xfv ../$DIRNAME-src.tgz
cd $DIRNAME
sh scripts/build.sh

