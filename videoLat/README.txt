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

Binary installers for Mac and source code can be downloaded via
<http://videolat.org>. Installation is optional: videoLat can
run in-place.

Binaries are also available in the Apple MacOS app store and the Apple iOS
app store.

Usage
=====

Instructions on using videoLat are available in the built-in help page and
on <http://videolat.org>.

Change Log
==========
2.1: Use CoreImage (get rid of3rd party libs), ported to newer OSX/iOS
2.0.3: CSV export failed if there were non-ASCII characters
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
- a Mac (10.12 and later have been tested, must be 64-bit capable, older releases may still work).
- XCode and the OSX build tools installed.
- the videoLat sources, obviously.

Build with

% xcodebuild -project videoLat-macos.xcodeproject build

This should create the application in "build/Release/videoLat.app".

Alternatively, you can 
1. Build videoLat, by opening videoLat-macos.xcodeproj and building it. The Debug and
Release targets are as expected, the Distribution target is what you should use
if you want to distribute a signed copy of your built application, and it will
only work if you have all the Apple magic certificates and whatnot installed.

2. If you want to create a binary or source distribution please make sure you
update the VIDEOLAT_VERSION variable in the xcode project "build settings" section.
Then you "Archive", then you "Validate" and "Distribute" that archive. For a
source distribution you run the script "scripts/mksrcdistr.sh" which will create
a tarball in the "build" directory and test that it builds. 

3. If you want to build the Doxygen documentation you should install Doxygen
via <http://www.doxygen.nl/> and GraphViz 
via <http://www.graphviz.org/> and install both. Then
you can use the toplevel Doxyfile or the XCode target.

Build instructions for iOS
==========================

Open videoLat-iOS.xcodeproj and build the app, either for the simulator or the real
device. Note that running under the simulator has only very limited functionality as
no audio and video input devices are available. Also note that for device builds you may need
to modify the build settings for code signing and provisioning so they refer to your identity
in stead of mine.

Instructions for building distributions are similar as for MacOS. Note that the version number
also needs to be opdated on the opening screen.

Contact
=======

For praise, complaints, bug reports and other feedback,
contact Jack Jansen <Jack.Jansen@cwi.nl> or use the sourceforge feedback
options.

Licenses
========

VideoLat is Copyright (c) 2010-2019, Stichting Centrum Wiskunde & Informatica,
licensed under GPL 3. Contact the authors in case you need different licensing
options.

