import sys

from Cocoa import *
import objc

HardwareLightProtocol = objc.protocolNamed('HardwareLightProtocol')

class LabJackDevice(NSObject, HardwareLightProtocol):

    def init(self):
        print 'LabJackDevice: init called', self
        self = super(LabJackDevice, self).init()
        self.delayLine = []
        return self
    
    def awakeFromNib(self):
        print 'LabJackDevice: awakeFromNib called', self
    
    
    def available(self):
        print 'LabJackDevice: available called', self
        return True
    
    def light_(self, level):
        print 'LabJackDevice: light_ called', self, level
        if not self.delayLine:
            self.delayLine = [level]*3
        self.delayLine.append(level)
        rv = self.delayLine[0]
        del self.delayLine[0]
        print 'LabJackDevice: light_ returning', rv
        return rv

    def deviceID(self):
        print 'LabJackDevice: deviceID called', self
        return 'LabJackID'

    def deviceName(self):
        print 'LabJackDevice: deviceName called', self
        return 'LabJack'