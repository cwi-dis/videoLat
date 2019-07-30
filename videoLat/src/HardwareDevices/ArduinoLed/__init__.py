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

class ArduinoLed(NSObject, HardwareLightProtocol):
    """Implementation of HardwareLightProtocol using a LabJack U3."""
    BAUD=115200

    def init(self):
        """ObjC-style initializer function"""
        if DEBUG: print 'ArduinoLed: init called', self
        self = super(ArduinoLed, self).init()
        self.arduino = None
        self._lastErrorMessage = None
        self._seqno = 0
        self.lock = threading.Lock()
        return self
    
    def dealloc(self):
        self.arduino = None

    def awakeFromNib(self):
        """Standard initializer"""
        if DEBUG: print 'ArduinoLed: awakeFromNib called', self
    
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
                print 'ArduinoLed: found', device
                if found:
                    self._lastErrorMessage = 'Multiple Arduinos connected to system'
                    return False
                found = device
        if not found:
            self._lastErrorMessage = 'No Arduinos connected'
            return False
        self.arduino = serial.Serial(found, baudrate=self.BAUD, timeout=4)
        print 'ArduinoLed: device opened, fd=%d' % self.arduino.fd
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
                if DEBUG: print 'ArduinoLed: available called', self
                if not self.arduino:
                    self._tryOpen()
                if DEBUG: print 'available: arduino is', self.arduino
                return not not self.arduino
            except:
                self._lastErrorMessage = 'Exception during ArduinoLed.available'
                traceback.print_exc()
            return False

    def light_(self, level):
        """Set output light level to 'level' and read return output light level."""
        with self.lock:
            if not self.arduino:
                self._lastErrorMessage = 'Arduino not connected'
                return -1
            self.arduino.flushInput()

            if level < 0.5:
                self.arduino.write('0\n')
            else:
                self.arduino.write('1\n')

            result = ''
            result = self.arduino.readline()
            if '0' in result:
                return 0.0
            if '1' in result:
                return 1.0
            self._lastErrorMessage = 'Unexpected Arduino reply: ' + repr(result)
            print 'ArduinoLed:', self._lastErrorMessage
            return -1

                    
    def deviceID(self):
        """Return the unique device-ID"""
        if DEBUG: print 'ArduinoLed: deviceID called', self
        return 'ArduinoLedID'

    def deviceName(self):
        """Return the human-readable device name"""
        if DEBUG: print 'ArduinoLed: deviceName called', self
        return 'ArduinoLed'

        
