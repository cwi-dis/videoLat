import socket
import time
import sys
import optparse
import thread

PORT=7243
INTERVAL=2
RESOLUTION=1000000

class TimeKeeper:
    def __init__(self, host, port, udp, keepopen, interval):
        self.host = host
        self.port = port
        self.udp = udp
        self.keepopen = keepopen or udp
        self.interval = interval
        self.sock = None
        if self.keepopen:
            self.sock = self._open()
        
    def _open(self):
        if self.udp:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        else:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((self.host, PORT))
        return s
        
    def step(self):
        if self.keepopen:
            sock = self.sock
        else:
            sock = self._open()
        then = int(time.time()*RESOLUTION)
        sock.send('%s\n' % then)
        if not self.udp:
            return self.recv_step(sock)
        return 0, 0, 0
        
    def recv_step(self, sock):
        data = sock.recv(1024)
        now = int(time.time()*RESOLUTION)
        data = data.strip()
        data = data.split()
        assert len(data) == 2
        then = int(data[0])
        theirs = int(data[1])
        delta = now - then
        ours = (now + then) / 2
        delta_clock = ours - theirs
        return (ours, delta_clock, delta)
        
    def recv_loop(self):
        while True:
            ours, delta_clock, delta = self.recv_step(self.sock)
            print "%6d %6d" % (delta_clock, delta)
            
        
    def run(self):
        if self.udp:
            thread.start_new_thread(self.recv_loop, ())
        while True:
            ours, delta_clock, delta = self.step()
            if not self.udp:
                print "%6d %6d" % (delta_clock, delta)
            time.sleep(self.interval)
            
def main():
    parser = optparse.OptionParser(usage="%prog [options] hostname")
    parser.add_option('-u', '--udp', action="store_true", dest="udp", help="Use UDP in stead of TCP", default=False)
    parser.add_option("-k", "--keepalive", action="store_true", dest="keepalive", help="Keep connection open", default=False)
    parser.add_option("-P", "--port", action="store", type="int", dest="port", help="Port to use", default=PORT)
    parser.add_option("-i", "--interval", action="store", type="float", dest="interval", help="Time (in seconds) between polls", default=INTERVAL)
    options, args = parser.parse_args()
    if len(args) != 1:
        parser.error("Exactly one hostname expected")
        
    tk = TimeKeeper(args[0], options.port, options.udp, options.keepalive, options.interval)
    tk.run()
    
if __name__ == '__main__':
    main()
    