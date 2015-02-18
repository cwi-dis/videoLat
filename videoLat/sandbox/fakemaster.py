import socket
import time
import json

def run(sock):
    try:
        while True:
            data = sock.recv(2048)
            if not data: break
            if data[0] == '{' and data[-1] == '}' and not '{' in data[1:-1]:
                dd = eval(data)
                print '%s\t%s\t%s\t%s\t%s' % (dd['code'], dd['count'], dd['masterDetectTime'], dd['slaveTime'], dd['masterTime'])
                rdd = dict(lastSlaveTime=dd['slaveTime'], lastMasterTime = int(time.time()*1000000))
                rdata = json.dumps(rdd)
                sock.send(rdata)
    except socket.error:
        print 'done'
                    
def main():
    lsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    lsock.bind(('',2345))
    lsock.listen(1)
    while True:
        print "Wait for connect"
        sock = lsock.accept()
        print 'Got connection', sock
        run(sock[0])
        
main()

