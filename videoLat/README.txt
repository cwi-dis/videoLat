videoLat README
===============

VideoLat is a tool to help you analyse video and audio delays, mainly aimed at
conferencing applications. Basically, it works by generating a barcode
on-screen and then measuring how long it takes until that same barcode is
detected by the camera. This method of measurement also takes into account
delays caused by camera, grabber hardware, video output card and the video
display.

VideoLat can take round-trip measurements, with the same system both
benerating and detecting the barcodes. With two copies of videoLat running,
one on each side, you can also do one-way measurements.

If you have access to the internals of the system-under-test it is possible
to take measurements there as well, because videoLat encodes the current
timestamp in the barcode.

More information on videoLat can be found at <http://www.videolat.org>, by
using the "help" command from within videoLat or by viewing the file
videoLat.help/Contents/Resources/videoLat.html in your browser.

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
2.0: iOS port, one-way measurements, UI revamp
1.0.3: Source-only, includes building the Doxygen documentation
1.0.2: Bug fix: calibrations could not be found due to sandboxing
1.0: First official release
0.90: complete refactoring, new user interface, added audio
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

Build Instructions for OSX, fast track
======================================

To build videoLat from source you need:
- a Mac (10.9-10.10 have been tested, must be 64-bit capable, older releases may still work),
- XCode and the OSX build tools installed,
- the Apple X11 compatibility package (if running 10.7 or earlier), or
  if you are on a later OSX you need to build and install libpng 1.5 from
  http://sourceforge.net/projects/libpng/files/libpng15, 
- and the videoLat sources, obviously.

Unpack the sources, go to the source directory, type

% sh scripts/build.sh

This should create the application in "build/Release/videoLat.app".

In case it fails, or if you want to do modifications, or create distributions
read the next section.

Build Instructions for OSX, detailed
====================================

To build videoLat from source you need a Mac (10.7 or later, capable of running
64-bit applications).
You need three third party packages:

- zbar (version 0.10 tested) for barcode generation
- zint (version 2.4.3 tested) for barcode detection

The first two should be included in a videoLat source distribution in the thirdParty
subdirectory.

You also need libpng 1.5, download from http://sourceforge.net/projects/libpng/files/libpng15/
and put the source tree in thirdParty/libpng-1.5.22. 

    (Actually, on 10.7 or earlier there is an Apple-installed libpng in te
    X11 package, so you don't have to download and build libpng unless you
    want to distribute your built binaries to systems running 10.8 or later).

Build the third-party packages:
1. Build libpng with:
	% mkdir thirdParty/installed
	% INST=`(cd thirdParty/installed ; pwd)`
	% cd thirdParty/libpng-1.5.22
	% ./configure \
		--prefix=$INST \
		CFLAGS="-arch i386 -arch x86_64" \
		CXXFLAGS="-arch i386 -arch x86_64" \
		LDFLAGS="-arch i386 -arch x86_64"
	% make
	% make install
2. Build zbar with:
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
		--without-python \
		--prefix=$INST \
		CFLAGS="-arch i386 -arch x86_64" \
		CXXFLAGS="-arch i386 -arch x86_64" \
		LDFLAGS="-arch i386 -arch x86_64"
	% make
	% make install

3. Build zint with:
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

4. Build videoLat, by opening videoLat.xcodeproj and building it. The Debug and
Release targets are as expected, the Distribution target is what you should use
if you want to distribute a signed copy of your built application, and it will
only work if you have all the Apple magic certificates and whatnot installed.

5. If you want to create a binary or source distribution please make sure you
update the VIDEOLAT_VERSION variable in the xcode project "build settings" section.
Then you "Archive", then you "Validate" and "Distribute" that archive. For a
source distribution you run the script "scripts/mksrcdistr.sh" which will create
a tarball in the "build" directory and test that it builds. 

6. If you want to build the Doxygen documentation you should install Doxygen
via <http://www.stack.nl/~dimitri/doxygen/> and GraphViz 
via <http://www.graphviz.org/Download_macos.php> and install both. Then
you can use the toplevel Doxyfile or the XCode target.

Build instructions for iOS
==========================

First you need to build the third party packages, for both iOS native and the simulator.
Download libpng from http://sourceforge.net/projects/libpng/files/libpng15/ and run

	$ sh scripts/build-ios.sh
	$ sh scripts/build-iossim.sh

If either of the builds fails you may need to edit the scripts to modify the IOS_VERSION
variable to refer to a version of iOS for which you have the SDK available. The scripts
install libpng, libzbar and libzint into thirdParty/installed-ios and thirdParty/installed-iossim,
respectively.

Next you open videoLat-iOS.xcodeproj and build the app, either for the simulator or the real
device. Note that running under the simulator has only very limited functionality as
no audio and video input devices are available. Also note that for device builds you may need
to modify the build settings for code signing and provisioning so they refer to your identity
in stead of mine.

Contact
=======

For praise, complaints, bug reports and other feedback,
contact Jack Jansen <Jack.Jansen@cwi.nl> or use the sourceforge feedback
options.

Licenses
========

VideoLat is Copyright (c) 2010-2015, Stichting Centrum Wiskunde & Informatica,
licensed under GPL 3. Contact the authors in case you need different licensing
options.

ZBar is licensed under LGPL 2.1.

ZInt is licensed under GPL 3.
