videoLat README
===============

VideoLat is a tool to help you analyse video delays, mainly aimed at
conferencing applications. Basically, it works by generating a barcode
on-screen and then measuring how long it takes until that same barcode is
detected by the camera. This method of measurement also takes into account
delays caused by camera, grabber hardware, video output card and the video
display.

VideoLat can take round-trip measurements, with the same system both
benerating and detecting the barcodes. A future release will also allow
asymetric measurements, using a videoLat-system on both ends.

If you have access to the internals of the system-under-test it is possible
to take measurements there as well, because videoLat encodes the current
timestamp in the barcode.

Download
========

Binary installers and source code can be downloaded via
<http://videolat.sourceforge.net>. Installation is optional: videoLat can
run in-place.

Usage
=====

Instructions on using videoLat are available in the built-in help page and
on <http://videolat.sourceforge.net>.

Change Log
==========
0.57: ported to AVFoundation, new zint version
0.56: attempt to cater for HD cameras. Also 10.7 is now minimum required OSX.
0.55: rebuild, some minor details
0.54: Monochrome detection works
0.54: LabJack hardware assist works
0.54: Added optional delay between output generation
0.53: better graph template handling
0.53: UI fixes
0.52: Fixed race condition that could cause early crash
0.52: Fixed race condition that could cause negative latencies
0.51: Added missing Help book

Build Instructions
==================

To build videoLat from source you need a Mac (10.6 has been tested).
You need two third party packages:

- zbar (version 0.10 tested) for barcode generation
- zint (version 2.4.3 tested) for barcode detection

These should be included in a videoLat source distribution in the thirdParty
subdirectory.

You also need a few more packages, install these through macports, all universal:

% sudo port install libiconv +universal
% sudo port install ImageMagick +universal
% sudo port install cmake +universal

(this list may be incomplete, please inform me if this is the case).

1. Build zbar with:
	% mkdir thirdParty/installed
	% INST=`(cd thirdParty/installed ; pwd)`
	% cd thirdParty/zbar-0.10-src
	% ./configure \
		--disable-dependency-tracking \
		--disable-video \
		--without-gtk \
		--without-qt \
		--without-xv \
		--without-imagemagick \
		--without-x \
		--without-xshm \
		--prefix=$INST \
		PKG_CONFIG_PATH=/opt/local/lib/pkgconfig \
		CFLAGS="-arch i386 -arch x86_64" \
		CXXFLAGS="-arch i386 -arch x86_64" \
		LDFLAGS="-arch i386 -arch x86_64"
	% make
	% make install

2. Build zint with:
	% mkdir thirdParty/installed
	% INST=`(cd thirdParty/installed ; pwd)`
	% cd thirdParty/zint-2.4.3
	% make prefix=$INST
	% make install prefix=$INST
	
   Alternatively you could use cmake but it doesn't work for me anymore:
	% cd thirdParty/zint-2.4.3
	% export PATH=/opt/local/bin:$PATH
	% mkdir build
	% cd build
	% export CMAKE_OSX_ARCHITECTURES="i386;x86_64"
	% cmake ..
	% make
	% make install prefix=$INST

3. Build videoLat, by opening videoLat.xcodeproj and building it.

Contact
=======

For praise, complaints, bug reports and other feedback,
contact Jack Jansen <Jack.Jansen@cwi.nl> or use the sourceforge feedback
options.

Licenses
========

VideoLat is Copyright (c) 2010, Stichting Centrum Wiskunde & Informatica,
licensed under GPL 3. Contact the authors in case you need different licensing
options.

ZBar is licensed under LGPL 2.1.

ZInt is licensed under GPL 3.
