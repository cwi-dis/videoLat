import sys
import os
import time
import socket
import threading
import Pyro4

class Clock:
    def __init__(self):
        self.epoch = time.time()
        self.maxError = 0
        
    def now(self):
        t = time.time() - self.epoch
        return int(t*1000000)

    def nowAt(self, at):
        return self.now(), at
        
class RemoteClock:
    def __init__(self, remoteClock):
        self.remoteClock = remoteClock
        self.pingTimes = []
        self.maxError = 0
        self._calibrate()
        
    def now(self):
        return self.remoteClock.now()
        
    def _calibrate(self):
        before = time.time()
        now = self.now()
        after = time.time()
        delta = int((after-before) * 1000000)
        self.pingTimes.append(delta)
        self.maxError = max(self.pingTimes)
            
class Server(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.daemon = Pyro4.Daemon()
        self.clock = Clock()
        
