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
SVNURL=`svn info | sed -ne 's/URL: //p'`
VIDEOLAT_VERSION=`sed -ne 's/.*VIDEOLAT_VERSION = \([^"].*\);/\1/p' videoLat.xcodeproj/project.pbxproj | head -1`
DIRNAME=videoLat-$VIDEOLAT_VERSION
rm -rf built/_src
mkdir -p built/_src
cd built/_src
svn co $SVNURL $DIRNAME
find $DIRNAME -name .svn -print | xargs rm -rf '{}' ';'
tar cfz ../$DIRNAME.tgz $DIRNAME
