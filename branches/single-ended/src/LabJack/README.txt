Instructions for using a LabJack U3 for camera-only or display-only measurements.

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
