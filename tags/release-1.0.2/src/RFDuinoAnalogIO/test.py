import arduinoserial
import time
import sys
import threading

PORT='/dev/tty.usbserial-DC008NKM'
BAUD=9600

rfduino = arduinoserial.SerialPort(PORT, BAUD)

seqno = 128
while True:
    print 'Again?',
    sys.stdin.readline()
    led = int(time.time()) & 1
    led = led*127
    seqno += 1
    if seqno > 255:
        seqno = 128
    print 'Sent: %d, led=%d' % (seqno, led)
    #rfduino.flushInput()
    rfduino.write(chr(seqno) + chr(led))
    #rfduino.drainOutput()
    count = 5
    while True:
        count -= 1
        if count == 0:
            print 'Out of read retry count.'
            break
        inseqno = rfduino.read_byte()
        if not inseqno:
            print 'No seqno'
            continue
        inseqno = ord(inseqno)
        if inseqno >= 128 and inseqno != seqno:
            print 'Expected seqno %d got %d' % (seqno, inseqno)
            continue
        elif inseqno != seqno:
            print 'Expected seqno %d got data %d' % (seqno, inseqno)
            continue
        
        indata = rfduino.read_byte()
        if not indata:
            print 'No data'
            continue
        indata = ord(indata)
        print 'Received: %d, data %d' % (inseqno, indata)
        break
    