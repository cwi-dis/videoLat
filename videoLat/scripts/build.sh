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
# Check for libpng16
#
if test -f thirdParty/libpng-1.6.*/configure; then
	echo libpng 1.6 sources found, building local copy
	(
		cd thirdParty/libpng-1.6.*
		./configure \
			--prefix=$INST \
			CFLAGS="-arch i386 -arch x86_64" \
			CXXFLAGS="-arch i386 -arch x86_64" \
			LDFLAGS="-arch i386 -arch x86_64"
		make clean
		make
		make install
	)
elif (libpng16-config --version > /dev/null 2>&1); then
	echo libpng 1.6 installed correctly, probably systemwide.
	echo **WARNING: this is not suitable for creating a distribution of videoLat

else
	echo libpng 1.6 not installed.
	echo Please download from http://sourceforge.net/projects/libpng/files/libpng16/
	echo Then unpack into thirdParty/libpng-1.6.xxx and re-run this script.
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
	make clean
	make
	make install
)
#
# Build zint
#
(
	cd thirdParty/zint-2.6.3.src
	rm -fr build
	mkdir build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX=$INST
	make
	make install
)
#
# Build videoLat
#
xcodebuild -project videoLat.xcodeproj
#
# All done
#
echo Your application should be waiting for you in `pwd`/build/Release
