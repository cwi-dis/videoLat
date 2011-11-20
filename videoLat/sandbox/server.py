import SocketServer
import time
import sys
import optparse

PORT=7243
RESOLUTION=1000000


class MyHandler(SocketServer.BaseRequestHandler):

    def handle(self):
        data = self.request.recv(1024).strip()
        if not data:
            return False
        now = int(time.time()*RESOLUTION)
        self.request.send('%s %s\n' % (data, str(now)))
        return True
        
class MyKeepAliveHandler(MyHandler):
    def handle(self):
        while MyHandler.handle(self):
            pass
            
class MyUDPHandler(SocketServer.BaseRequestHandler):
    def handle(self):
        ## print '<--', self.request
        data = self.request[0].strip()
        if not data:
            return False
        now = int(time.time()*RESOLUTION)
        self.request[1].sendto('%s %s\n' % (data, str(now)), self.client_address)
        return True
    
            
def main():
    parser = optparse.OptionParser()
    parser.add_option('-u', '--udp', action="store_true", dest="udp", help="Use UDP in stead of TCP", default=False)
    parser.add_option("-k", "--keepalive", action="store_true", dest="keepalive", help="Keep connection open", default=False)
    parser.add_option("-P", "--port", action="store", type="int", dest="port", help="Port to use", default=PORT)
    options, args = parser.parse_args()
    if args:
        parser.error("Too many arguments")
    if options.keepalive:
        klass = MyKeepAliveHandler
    else:
        klass = MyHandler
    
    if options.udp:
        server = SocketServer.UDPServer(('', options.port), MyUDPHandler)
    else:
        server = SocketServer.TCPServer(('', options.port), klass)
    server.serve_forever()
    
if __name__ == '__main__':
    main()
    