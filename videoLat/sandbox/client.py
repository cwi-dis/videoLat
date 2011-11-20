import socket
import time
import sys


PORT=7243
INTERVAL=2
RESOLUTION=1000000

class TimeKeeper:
    def __init__(self, host, keepopen):
        self.host = host
        self.keepopen = keepopen
        self.sock = None
        if keepopen:
            self.sock = self._open()
        
    def _open(self):
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
        data = sock.recv(1024)
        now = int(time.time()*RESOLUTION)
        ## print '-->', then
        ## print '<--', data
        data = data.strip()
        data = data.split()
        assert len(data) == 2
        assert int(data[0]) == then
        theirs = int(data[1])
        delta = now - then
        ours = (now + then) / 2
        delta_clock = ours - theirs
        return (ours, delta_clock, delta)
        
    def run(self):
        while True:
            ours, delta_clock, delta = self.step()
            print "%6d %6d" % (delta_clock, delta)
            time.sleep(INTERVAL)
            
def main():
    keepopen = False
    if len(sys.argv) > 1 and sys.argv[1] == '-k':
        keepopen = True
        del sys.argv[1]
    if len(sys.argv) != 2:
        print 'Usage: %s [-k] hostname' % sys.argv[0]
        sys.exit(1)
        
    tk = TimeKeeper(sys.argv[1], keepopen)
    tk.run()
    
if __name__ == '__main__':
    main()
    