import sys
import os

# Import the labjack support
import u3

# Import the ObjC/Cocoa support
from Cocoa import *
import objc
import threading

DEBUG=True

HardwareLightProtocol = objc.protocolNamed('HardwareLightProtocol')

class LabJack(NSObject, HardwareLightProtocol):
    """Implementation of HardwareLightProtocol using a LabJack U3."""
    ## Output port to use,  LED is attached to port FIO4
    OUTPUT_PORT = 4
    ## Input port to use, phototransistor/opamp are attached to port FIO5
    INPUT_PORT = 5
    ## @var u3Device
    # the u3.U3 interface to the actual hardware
    

    def init(self):
        """ObjC-style initializer function"""
        if DEBUG: print 'LabJack: init called', self
        self = super(LabJack, self).init()
        self.u3Device = None
        self._lastErrorMessage = None
        self._lastOutputState = None
        self.lock = threading.Lock()
        return self
    
    def awakeFromNib(self):
        """Standard initializer"""
        if DEBUG: print 'LabJack: awakeFromNib called', self
    
    def _tryOpen(self):
        # Open the device
        try:
            self.u3Device = u3.U3()
        except u3.LabJackException, arg:
            if DEBUG: print 'LabJack._tryOpen: Cannot open LabJack U3: %s' % arg
            self._lastErrorMessage = 'Cannot open LabJack U3: %s' % arg
            return
        # Configure all ports as digital
        conf = self.u3Device.configIO(0)
        if DEBUG: print 'LabJack: config=', conf
        rv = self.u3Device.getFeedback([
            u3.BitDirWrite(self.INPUT_PORT, 0),
            u3.BitDirWrite(self.OUTPUT_PORT, 1),
            u3.BitDirRead(self.INPUT_PORT),
            u3.BitDirRead(self.OUTPUT_PORT)
            ])
        if DEBUG: print 'LabJack: getFeedback returned', rv

    def lastErrorMessage(self):
        """Returns last error message from hardware/library, for display to the user."""
        with self.lock:
            rv = self._lastErrorMessage
            self._lastErrorMessage = None
            return rv

    def available(self):
        """Returns true if the library is installed and the hardware connected."""
        with self.lock:
            try:
                if not self.u3Device:
                    if DEBUG: print 'LabJack.available: called with self=', self
                    #import pdb ; pdb.set_trace()
                    self._tryOpen()
                    if DEBUG: print 'LabJack.available: u3device is', self.u3Device
                return not not self.u3Device
            except:
                if DEBUG: print 'LabJack.available: exception during _tryopen'
                self._lastErrorMessage = 'Exception during LabJack.available'
                if not DEBUG:
                    print 'Exception during LabJack.available'
                    return False
                import pdb
                pdb.post_mortem()
    
    def light_(self, level):
        """Set output light level to 'level' and read return input light level."""
        with self.lock:
            try:
                if DEBUG: print 'LabJack: light_ called', self, level,
                if not self.u3Device:
                    return 0
                # Note: the logic is reversed here: 0 means light
                commands = [u3.BitStateRead(self.INPUT_PORT)]
                if level != self._lastOutputState:
                    self._lastOutputState = level
                    commands.append(u3.BitDirWrite(self.OUTPUT_PORT, 1))
                    if level >= 0.5:
                        commands.append(u3.BitStateWrite(self.OUTPUT_PORT, 1))
                    else:
                        commands.append(u3.BitStateWrite(self.OUTPUT_PORT, 0))
                rv = self.u3Device.getFeedback(commands)
                if DEBUG: print 'returned', rv
                return rv[0]
            except u3.LabJackException, arg:
                self._lastErrorMessage = 'Exception during LabJack.light_: %s' % arg
            except:
                self._lastErrorMessage = 'Exception during LabJack.light_'
                if not DEBUG:
                    print 'Exception during LabJack.light_'
                    return 0
                import pdb
                pdb.post_mortem()
            return 0
                    
    def deviceID(self):
        """Return the unique device-ID"""
        if DEBUG: print 'LabJack: deviceID called', self
        return 'LabJackID'

    def deviceName(self):
        """Return the human-readable device name"""
        if DEBUG: print 'LabJack: deviceName called', self
        return 'LabJack'
