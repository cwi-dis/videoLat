Contents
========

This folder (actually a Python package) contains the interface for the LabJack U3
hardware driver for videoLat.

__init__.py is the main driver module.

u3.py, LabJackPython.py and Modbus.py are the interface to the Exodriver for the U3 (see below)
and have been copied verbatim from www.labjack.com.

Hardware contains the schematics you should build to interface the LED and
phototransistor to the U3 interface.

Instructions for using a LabJack U3 for camera-only or display-only measurements
================================================================================

- Buy the device.

- Download the drivers via http://labjack.com/support/software

- Run videoLat, do File->Open Hardware Support Folder

- Start a Terminal session in this folder. You may need "sudo" for some of the
  commands. Some of the version numbers may differ for your labjack driver.
  
- Copy /usr/local/liblabjackusb-2.0.3.dylib into the current directory,
  name it "liblabjackusb.dylib":
  
  	$ cp /usr/local/lib/liblabjackusb-2.0.3.dylib liblabjackusb.dylib
  	
- Copy /usr/local/lib/libusb-1.0.0.dylib into the current directory:

	$ cp /usr/local/lib/libusb-1.0.0.dylib libusb-1.0.0.dylib
	
- Change the reference to libusb in liblabjackusb.dylib:

    $ install_name_tool -change /usr/local/lib/libusb-1.0.0.dylib @loader_path/libusb-1.0.0.dylib liblabjackusb.dylib
    
- Run videoLat again, verify that New->Hardware Calibrate->LabJack can now open the device.
  If not, try running videoLat from the command line and check whether the debug output gives
  any clue.
  
- Build the hardware as shown in the Hardware/hardware.pdf image.

Using the LabJack for Measurements
==================================

Now first run a hardware calibrate.
Point the LED and the Phototransistor at each other in a dark place.
This should give a calibration of 4ms (or very close to it) according to the LabJack documentation.

There is an issue somewhere (videoLat? labjack software? Exodriver?) that meas that often
you cannot use the LabJack a second time. In this case: exit videoLat, unplug LabJack, replug
LabJack, restart videoLat.

Next you can run a camera calibration. Put the LED and the camera in a dark place. Run.
For a screen calibration point the phototransistor at your screen (without too much stray light) and run.
