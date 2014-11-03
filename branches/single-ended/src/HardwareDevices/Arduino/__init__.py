import sys
import os
import time

# Import the ObjC/Cocoa support
from Cocoa import *
import objc

import arduinoserial

DEBUG=False

# Sequence that should resynchronise things
RESYNC="\xff\xff\xff\xff"

HardwareLightProtocol = objc.protocolNamed('HardwareLightProtocol')

class Arduino(NSObject, HardwareLightProtocol):
    """Implementation of HardwareLightProtocol using a LabJack U3."""
    PORT='/dev/tty.usbserial-DC008NKM'
    BAUD=115200

    def init(self):
        """ObjC-style initializer function"""
        if DEBUG: print 'Arduino: init called', self
        self = super(Arduino, self).init()
        self.arduino = None
        self._lastErrorMessage = None
        self._seqno = 0
        return self
    
    def awakeFromNib(self):
        """Standard initializer"""
        if DEBUG: print 'Arduino: awakeFromNib called', self
    
    def _tryOpen(self):
        # Open the device
        try:
            self.arduino = arduinoserial.SerialPort(self.PORT, self.BAUD)
        except OSError, arg:
            self._lastErrorMessage = 'Cannot open: %s' % arg
            return
        self.arduino.write(RESYNC)

    def lastErrorMessage(self):
        """Returns last error message from hardware/library, for display to the user."""
        return self._lastErrorMessage

    def available(self):
        """Returns true if the library is installed and the hardware connected."""
        try:
            if DEBUG: print 'Arduino: available called', self
            if not self.arduino:
                self._tryOpen()
            if DEBUG: print 'available: arduino is', self.arduino
            return not not self.arduino
        except:
            self._lastErrorMessage = 'Exception during Arduino.available'
            if not DEBUG:
                print 'Exception during Arduino.available'
                return False
            import pdb
            pdb.post_mortem()

    def _newSeqNo(self):
        if self._seqno < 128 or self._seqno >= 192:
            self._seqno = 128
        else:
            self._seqno += 1
        return self._seqno
        
    def light_(self, level):
        """Set output light level to 'level' and read return input light level."""
        if not self.arduino:
            return -1
        seqno = self._newSeqNo()
        iLevel = int(level * 127)
        self.arduino.write(chr(seqno) + chr(iLevel))
        
        inseqno = 255
        while inseqno == 255:
            inseqno = self.arduino.read_byte()
            if not inseqno:
                self._lastErrorMessage = 'No data (seqno) from Arduino'
                return -1
            inseqno = ord(inseqno)

        if inseqno < 128:
            self._lastErrorMessage = 'Sync error, got data in stead of seqno from arduino'
            self.arduino.write(RESYNC)
            return -1
            
        indata = self.arduino.read_byte()
        if not indata: 
            self._lastErrorMessage = 'No data (analog value) from Arduino'
            return -1

        indata = ord(indata)
        if indata >= 128:
            self._lastErrorMessage = 'Sync error, got seqno (%d) in stead of data from ardino' % indata
            return -1
            
        if inseqno > 192:
            self._lastErrorMessage = 'Received error %d, %d from arduino' % (inseqno, indata)
            return -1
            
        if inseqno != seqno:
            self._lastErrorMessage = 'Arduino sent seqno %d, expected %d' % (inseqno, seqno)
            return 0.5
            
        return round(float(indata) / 127.0, 2)
                    
    def deviceID(self):
        """Return the unique device-ID"""
        if DEBUG: print 'Arduino: deviceID called', self
        return 'ArduinoID'

    def deviceName(self):
        """Return the human-readable device name"""
        if DEBUG: print 'Arduino: deviceName called', self
        return 'Arduino'

if 0:  # __name__ == '__main__':
    import random
    
    d = Arduino.alloc().init()
    if not d.available():
        print 'Device not avaialable:',d.lastErrorMessage()
    
    while True:
        outlevel = round(random.random())
        inlevel = d.light_(outlevel)
        print 'OUT: %f\tIN:%f' % (outlevel, inlevel)
        if inlevel == 0.5:
            print '   error', d.lastErrorMessage()
        time.sleep(1)
        
