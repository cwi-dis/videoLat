import time
import sys
import threading
sys.path.append('..')
import arduinoserial

PORT='/dev/tty.usbserial-DC008NKM'
BAUD=9600

RESYNC = chr(255)*4

rfduino = arduinoserial.SerialPort(PORT, BAUD)

seqno = 128
rfduino.write(RESYNC)

while True:
    print 'Again?',
    sys.stdin.readline()
    led = int(time.time()) & 1
    led = led*127
    seqno += 1
    if seqno >= 192:
        seqno = 128
    print 'Sent: seqno=%d, led=%d' % (seqno, led)

    rfduino.write(chr(seqno) + chr(led))
    while True:
        inseqno = rfduino.read_byte()
        if not inseqno:
            print 'No seqno, resync and restart read'
            rfduino.write(RESYNC)
            continue
        inseqno = ord(inseqno)
        if inseqno == 255:
            print 'resync byte read, restart read'
            continue

        if inseqno < 128:
            print 'Got databyte in stead of sequence number, resync and restart read'
            rfduino.write(RESYNC)
            continue

        indata = rfduino.read_byte()
        if not indata:
            print 'No data, resync and restart read'
            rfduino.write(RESYNC)
            continue
        indata = ord(indata)
        if indata >= 128:
            print 'Data %d >= 128, resync and restart read' % indata
            rfduino.write(RESYNC)
            continue

        if inseqno > 192:
            print 'Received error %d, data %d' % (inseqno, indata)
            break
            
        if inseqno != seqno:
            print 'Expected seqno %d got %d' % (seqno, inseqno)
            continue
        
        print 'Received: %d, data %d' % (inseqno, indata)
        break
    
