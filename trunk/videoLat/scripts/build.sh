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

#
# Check for libpng15
#
if (libpng15-config --version > /dev/null 2>&1); then
	echo libpng 1.5 installed correctly
else
	echo libpng 1.5 not installed.
	echo Please download, build and install from http://sourceforge.net/projects/libpng/files/libpng15/
	exit 1
fi

#
# build zbar
#
(
	cd thirdParty/zbar-0.10-src
	./configure \
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
			PKG_CONFIG_PATH=/opt/local/lib/pkgconfig \
			CFLAGS="-arch i386 -arch x86_64" \
			CXXFLAGS="-arch i386 -arch x86_64" \
			LDFLAGS="-arch i386 -arch x86_64"
	make
	make install
)
#
# Build zint
#
(
	cd thirdParty/zint-2.4.3
	make prefix=$INST
	make install prefix=$INST
)
#
# Build videoLat
#
xcodebuild -project videoLat.xcodeproj
#
# All done
#
echo Your application should be waiting for you in `pwd`/build/Release
