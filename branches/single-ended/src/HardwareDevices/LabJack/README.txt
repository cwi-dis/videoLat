Contents
========

This folder (actually a Python package) contains the interface for the LabJack U3
hardware driver for videoLat.

__init__.py is the main driver module.

u3.py, LabJackPython.py and Modbus.py are the interface to the Exodriver for the U3 (see below)
and have been copied verbatim from www.labjack.com.

Hardware contains the schematics you should build to interface the LED and
phototransistor to the U3 interface.

Instructions for using a LabJack U3 for camera-only or display-only measurements.
=================================================================================

- Buy the device.
- Download the drivers via http://labjack.com/support/software
- Build the hardware as shown in the toplevel hardware/hardware.pdf image

There is an issue somewhere (videoLat? labjack software? Exodriver?) that meas that often
you cannot use the LabJack a second time. In this case: exit videoLat, unplug LabJack, replug
LabJack, restart videoLat.

Now first run a hardware calibrate.
Point the LED and the Phototransistor at each other in a dark place.
This should give a calibration of 4ms (or very close to it) according to the LabJack documentation.

There is an issue somewhere (videoLat? labjack software? Exodriver?) that meas that often
you cannot use the LabJack a second time. In this case: exit videoLat, unplug LabJack, replug
LabJack, restart videoLat.

Next you can run a camera calibration. Put the LED and the camera in a dark place. Run.
