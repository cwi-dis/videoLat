import sys
import os
import time
import threading
import traceback


# Import the ObjC/Cocoa support
from Cocoa import *
import objc
objc.setVerbose(1)
from objc import super
import serial
import serial.tools.list_ports

DEBUG=False

HardwareLightProtocol = objc.protocolNamed('HardwareLightProtocol')

class ArduinoInOut(NSObject, HardwareLightProtocol):
    """Implementation of HardwareLightProtocol using an Arduino."""
    BAUD=115200

    def init(self):
        """ObjC-style initializer function"""
        if DEBUG: print 'ArduinoInOut: init called', self
        self = super(ArduinoInOut, self).init()
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
        if DEBUG: print 'ArduinoInOut: awakeFromNib called', self
    
    def _tryOpen(self):
        """Open a serial link to the one arduino connected to this system"""
        found = None
        allPorts = serial.tools.list_ports.comports()
        for p in allPorts:
            if hasattr(p, 'description'):
                description = p.description
                device = p.device
            else:
                description = p[1]
                device = p[0]
            if description.startswith('Arduino') or description.startswith('FT232'):
                print 'ArduinoInOut: found', device
                if found:
                    self._lastErrorMessage = 'Multiple Arduinos connected to system'
                    return False
                found = device
        if not found:
            self._lastErrorMessage = 'No Arduinos connected'
            return False
        self.arduino = serial.Serial(found, baudrate=self.BAUD, timeout=4)
        print 'ArduinoInOut: device opened, fd=%d' % self.arduino.fd
        return True

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
                if DEBUG: print 'ArduinoInOut: available called', self
                if not self.arduino:
                    self._tryOpen()
                if DEBUG: print 'available: arduino is', self.arduino
                return not not self.arduino
            except:
                self._lastErrorMessage = 'Exception during ArduinoInOut.available'
                traceback.print_exc()
            return False

    def light_(self, level):
        """Set output light level to 'level' and read return output light level."""
        with self.lock:
            if not self.arduino:
                self._lastErrorMessage = 'Arduino not connected'
                return -1
            self._lastErrorMessage = None
            if level < 0.5:
                if DEBUG: print 'ArduinoInOut: send 0'
                self.arduino.write('0\n')
            else:
                if DEBUG: print 'ArduinoInOut: send 1'
                self.arduino.write('1\n')

            result = self.arduino.readline()
            if DEBUG: print 'ArduinoInOut: recv', repr(result)
            result = result.strip()
            if DEBUG: print 'ArduinoInOut: strip', repr(result)
            # Try one more time if empty
            if not result:
                result = self.arduino.readline()
                if DEBUG: print 'ArduinoInOut: recv', repr(result)
                result = result.strip()
                if DEBUG: print 'ArduinoInOut: strip', repr(result)
            self.arduino.flushInput()
            try:
                return int(result)/255.0
            except ValueError:
                pass
            self._lastErrorMessage = 'Unexpected Arduino reply: ' + repr(result)
            print 'ArduinoInOut:', self._lastErrorMessage
            return -1.0

                    
    def deviceID(self):
        """Return the unique device-ID"""
        if DEBUG: print 'ArduinoInOut: deviceID called', self
        return 'ArduinoInOut'

    def deviceName(self):
        """Return the human-readable device name"""
        if DEBUG: print 'ArduinoInOut: deviceName called', self
        return 'ArduinoInOut'
        
    def switchToDeviceWithName_(self, name):
        """Switch to this device. Returns true if it is "our" device"""
        return name == "ArduinoInOut"

        
