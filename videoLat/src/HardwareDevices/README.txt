This folder contains the drivers for the supported devices to do hardware
measurements. The directories are actually Python packages, folders containing
a file called __init__.py, which contains the code to implement the driver.

Each of the folders contains instructions on how to use the driver, 
with which hardware, and possibly schematics on what hardware should be built.

Some older drivers (RFDuino, LabJack, lightphone) have stopped working over
the years due to OSX changes, and I didn't have the inclination to keep them
working. If you want them and invest the trouble to revive them please check
the github repository.
