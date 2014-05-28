import sys
import os
import arduinoserial
import time
import sys
import threading
import Queue

MINSEQNO = 128
MAXSEQNO = 128 + 31
PORT='/dev/tty.usbserial-DC008NKM'
BAUD=9600

DEBUG=True

class ArduinoAnalogIO(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = True
        self.seqno = MINSEQNO
        self.buffer = Queue.Queue()
        self._open()
        self.start()
        
    def _open(self):
        self.serial = arduinoserial.SerialPort(PORT, BAUD)
        
    def _writeBuffer(self, seqno, value):
        self.buffer.put((seqno, value), True)
        
    def _readBuffer(self):
        ok = True
        seqno = value = None
        try:
            seqno, value = self.buffer.get(True, 1.0)
        except Queue.Empty:
            ok = False
        return ok, seqno, value
        
    def writeValue(self, value):
        self.seqno += 1
        if self.seqno >= MAXSEQNO:
            self.seqno = MINSEQNO
        cSeqno = chr(self.seqno)
        iValue = int(value * 127)
        cValue = chr(iValue)
        self.serial.write(cSeqno + cValue)
        return self.seqno
        
    def readValue(self, seqno):
        while True:
            ok, rSeqno, rValue = self._readBuffer()
            if not ok:
                if DEBUG:
                    print 'readValue(%d): no data received' % seqno
                return 0
            if rSeqno == seqno:
                return (rValue / 127.0)
            if DEBUG:
                print 'readValue(%d): received seqno %d, data %d' % (seqno, rSeqno, rValue)
                
    def run(self):
        while True:
                inByte1 = self.serial.read_byte()
                if inByte1:
                    inSeqno = ord(inByte1)
                    if inSeqno < 128:
                        print 'ArduinoAnalogIO: expected seqno (128..255) got 0x%x' % inSeqno
                    else:
                        inByte2 = self.serial.read_byte()
                        if inByte2:
                            inValue = ord(inByte2)
                            if inValue < 128:
                                self._writeBuffer(inSeqno, inValue)
                            
def _test():
    ard = ArduinoAnalogIO()
    while True:
        t = int(time.time()) & 1
        seqno = ard.writeValue(t)
        newValue = ard.readValue(seqno)
        print '%d -> %f' % (t, newValue)
        time.sleep(0.1)
        
def _test2():
    ard = ArduinoAnalogIO()
    outValue = 0.1
    while True:
        start = time.time()
        seqno = ard.writeValue(outValue)
        inValue = ard.readValue(seqno)
        inValue = int(round(inValue))
        if inValue == outValue:
            print '%d: %f' % (inValue, time.time() - start)
            start = time.time()
            outValue = 1.0 - outValue
        elif time.time() - start > 1:
            print '%d: timeout' % (inValue)
            start = time.time()
            outValue = 1 - outValue

if __name__ == '__main__':
    _test2()
    