import SocketServer
import time
import sys

PORT=7243
RESOLUTION=1000000


class MyHandler(SocketServer.BaseRequestHandler):

    def handle(self):
        data = self.request.recv(1024).strip()
        if not data:
            return False
        now = int(time.time()*RESOLUTION)
        self.request.send('%s %s' % (data, str(now)))
        return True
        
class MyKeepAliveHandler(MyHandler):
    def handle(self):
        while MyHandler.handle(self):
            pass
            
def main():
    if len(sys.argv) > 1 and sys.argv[1] == '-k':
        klass = MyKeepAliveHandler
    else:
        klass = MyHandler
        
    server = SocketServer.TCPServer(('', PORT), klass)
    server.serve_forever()
    
if __name__ == '__main__':
    main()
    