Getting started with using an RFDuino to hardware black/white measurements.
Undoubtedly with minor modifications this'll work with any arduino.

Notes taken while doing this the second time:-)

- Get an rfduino (rfduino.com)
- Get the rfduino quickstart guide (google for "rfduino quick start guide")
- Get the RFDuino library.
- Get the arduino development environment from http://www.arduino.cc/en/Main/Software
  NOTE you want 1.5.X, not 1.0.X.
- Follow the instructions in the quickstart guide to put the rfduino stuff into
  the arduino application. Look at the screenshots, if you see something different
  you've downloaded the wrong release of the arduino development environment.
- Follow the instructions in the quickstart guide about installing the serial driver.
- Run arduino. NOTE: the installation procedure above seems to break the
  signature (at least for 1.5.8). This means you have to run from
  the command line...
- Build the circuit that isn't described yet, to be done.
- Select the right board and the right port.
- Download RFDuinoAnalogIO.ino into the RFDuino
- 