import sys
import os

# Import the labjack support
import u3

# Import the ObjC/Cocoa support
from Cocoa import *
import objc

DEBUG=False

HardwareLightProtocol = objc.protocolNamed('HardwareLightProtocol')

class LabJackDevice(NSObject, HardwareLightProtocol):
    OUTPUT_PORT = 4 # LED is attached to port FIO4
    INPUT_PORT = 5  # Phototransistor/opamp are attached to port FIO5

    def init(self):
        if DEBUG: print 'LabJackDevice: init called', self
        self = super(LabJackDevice, self).init()
        self.u3Device = None
        self._lastErrorMessage = None
        return self
    
    def awakeFromNib(self):
        if DEBUG: print 'LabJackDevice: awakeFromNib called', self
    
    def _tryOpen(self):
        # Open the device
        try:
            self.u3Device = u3.U3()
        except u3.LabJackException, arg:
            self._lastErrorMessage = 'Cannot open: %s' % arg
            return
        # Configure all ports as digital
        self.u3Device.configIO(0)
        self.u3Device.getFeedback([
            u3.BitDirWrite(self.INPUT_PORT, 0),
            u3.BitDirWrite(self.OUTPUT_PORT, 1),
            ])

    def lastErrorMessage(self):
        return self._lastErrorMessage

    def available(self):
        try:
            if DEBUG: print 'LabJackDevice: available called', self
            if not self.u3Device:
                self._tryOpen()
            if DEBUG: print 'available: u3device is', self.u3Device
            return not not self.u3Device
        except:
            self._lastErrorMessage = 'Exception during LabJackDevice.available'
            if not DEBUG:
                print 'Exception during LabJackDevice.available'
                return False
            import pdb
            pdb.post_mortem()
    
    def light_(self, level):
        try:
            if DEBUG: print 'LabJackDevice: light_ called', self, level
            if not self.u3Device:
                return 0
            # Note: the logic is reversed here: 0 means light
            if level < 0.5:
                outCmd = u3.BitStateWrite(self.OUTPUT_PORT, 1)
            else:
                outCmd = u3.BitStateWrite(self.OUTPUT_PORT, 0)
            inCmd = u3.BitStateRead(self.INPUT_PORT)
            rv = self.u3Device.getFeedback([inCmd, outCmd])
            if DEBUG: print 'labJackDevice: light_: returned', rv
            return rv[0]
        except u3.LabJackException, arg:
            self._lastErrorMessage = 'Exception during LabJackDevice.light_: %s' % arg
        except:
            self._lastErrorMessage = 'Exception during LabJackDevice.light_'
            if not DEBUG:
                print 'Exception during LabJackDevice.light_'
                return 0
            import pdb
            pdb.post_mortem()
        return 0
                    
    def deviceID(self):
        if DEBUG: print 'LabJackDevice: deviceID called', self
        return 'LabJackID'

    def deviceName(self):
        if DEBUG: print 'LabJackDevice: deviceName called', self
        return 'LabJack'
