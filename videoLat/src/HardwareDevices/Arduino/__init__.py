import sys
import os
import time
import threading


# Import the ObjC/Cocoa support
from Cocoa import *
import objc
objc.setVerbose(1)
from objc import super
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
        self.lock = threading.Lock()
        return self
    
    def dealloc(self):
        self.arduino = None

    def stop(self):
        self.arduino = None
    
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
        time.sleep(2)
        self._resync()
        print 'Arduino: device opened, fd=%d' % self.arduino.fd
        
    def _resync(self):
        self.arduino.write(RESYNC)
        time.sleep(1)
        self.arduino.flushInput()

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
                if DEBUG: print 'Arduino: available called', self
                if not self.arduino:
                    self._tryOpen()
                if DEBUG: print 'available: arduino is', self.arduino
                return not not self.arduino
            except:
                self._lastErrorMessage = 'Exception during Arduino.available'
                if not DEBUG:
                    print 'Arduino: Exception during Arduino.available'
                    return False
                import pdb
                pdb.post_mortem()

    def _newSeqNo(self):
        if self._seqno < 129 or self._seqno >= 192:
            self._seqno = 129
        else:
            self._seqno += 1
        return self._seqno
        
    def light_(self, level):
        """Set output light level to 'level' and read return input light level."""
        with self.lock:
            if not self.arduino:
                return -1
            seqno = self._newSeqNo()
            iLevel = int(level * 127)
            wData = chr(seqno) + chr(iLevel)
            if DEBUG: print 'arduino.write(%s)' % repr(wData)
            self.arduino.write(wData)
            
            inseqno = 255
            while inseqno == 255:
                inseqno = self.arduino.read_byte()
                if not inseqno:
                    self._lastErrorMessage = 'No data (seqno) from Arduino'
                    if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                    return -1
                inseqno = ord(inseqno)

            if inseqno < 128:
                self._lastErrorMessage = 'Sync error, got data in stead of seqno from arduino'
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1
                
            indata = self.arduino.read_byte()
            if not indata: 
                self._lastErrorMessage = 'No data (analog value) from Arduino'
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1

            indata = ord(indata)
            if indata >= 128:
                self._lastErrorMessage = 'Sync error, got seqno (%d) in stead of data from ardino' % indata
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1
                
            if inseqno > 192:
                self._lastErrorMessage = 'Received error %d, %d from arduino' % (inseqno, indata)
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1
                
            if inseqno != seqno:
                self._lastErrorMessage = 'Received seqno %d from Arduino, expected %d' % (inseqno, seqno)
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1
            
            if indata == 0:
                self._lastErrorMessage = 'Received questionable analog value 0 from Arduino'
                if 1 or DEBUG: print 'Arduino error:', self._lastErrorMessage
                self._resync()
                return -1
            rv = round(float(indata) / 127.0, 2)
            if DEBUG: print 'light(%f=%d) -> %f=%d' % (level, iLevel, rv, indata)
            return rv
                    
    def deviceID(self):
        """Return the unique device-ID"""
        if DEBUG: print 'Arduino: deviceID called', self
        return 'Arduino'

    def deviceName(self):
        """Return the human-readable device name"""
        if DEBUG: print 'Arduino: deviceName called', self
        return 'Arduino'
        
    def switchToDeviceWithName_(self, name):
        """Switch to this device. Returns true if it is "our" device"""
        return name == "Arduino"

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
        
