#!/usr/bin/python
import cgi
import cgitb
import os
import sys

cgitb.enable()

# Directory structure:
# basedir/
#         blacklisted/
#                     247c5cd7-f4c1-4153-ba96-e86dc2088655 - Measurement that should not be uploaded (inspected, and faulty)
#         measurementTypeID/
#                           machineTypeID/
#                                         inputDeviceID/
#                                                       247c5cd7-f4c1-4153-ba96-e86dc2088655
#                                         outputDeviceID/
#                                                        247c5cd7-f4c1-4153-ba96-e86dc2088655
BASEDIR=os.path.join(os.path.dirname(os.path.dirname(__file__)), "measurements")

class Uploader:
    def __init__(self):
        self.op = None
        self.uuid = None
        self.measurementTypeID = None
        self.machineTypeID = None
        self.inputDeviceID = None
        self.outputDeviceID = None
        self.dataSize = None
        self.data = None
        self.pathname = None
        assert os.path.exists(BASEDIR)
        
    def parseArguments(self):
        if 'REQUEST_METHOD' in os.environ and os.environ['REQUEST_METHOD'] == 'PUT':
            os.environ['REQUEST_METHOD'] = 'GET'
        args = cgi.FieldStorage()
        self.op = args.getfirst('op', None)
        self.uuid = args.getfirst('uuid', None)
        self.measurementTypeID = args.getfirst('measurementTypeID', None)
        self.machineTypeID = args.getfirst('machineTypeID', None)
        self.inputDeviceID = args.getfirst('inputDeviceID', None)
        self.outputDeviceID = args.getfirst('outputDeviceID', None)
        self.dataSize = args.getfirst('dataSize', None)
        assert self.op
        assert self.uuid
        assert self.measurementTypeID
        assert self.machineTypeID
        assert self.inputDeviceID or self.outputDeviceID
        assert  not (self.inputDeviceID and self.outputDeviceID)
        if self.dataSize:
            self.data = sys.stdin.read()
            dataSize = int(self.dataSize)
            assert len(self.data) == dataSize, "Expected %d bytes got %d bytes" % (dataSize, len(self.data))
        
    def run(self):
        self.parseArguments()
        if self.op == "check":
            testpath = os.path.join(BASEDIR, 'blacklisted', self.uuid)
            if os.path.exists(testpath):
                self.output(False)
                return
            testpath = os.path.join(BASEDIR, self.measurementTypeID, self.machineTypeID)
            if self.inputDeviceID:
                testpath = os.path.join(testpath, self.inputDeviceID)
            elif self.outputDeviceID:
                testpath = os.path.join(testpath, self.outputDeviceID)
            if os.path.exists(os.path.join(testpath, self.uuid)):
                self.output(False)
                return
            if os.path.exists(testpath):
                self.output(False)
                return
            self.output(True)
            return
        elif self.op == "upload":
            assert self.data
            dirpath = os.path.join(BASEDIR, self.measurementTypeID, self.machineTypeID)
            if self.inputDeviceID:
                dirpath = os.path.join(dirpath, self.inputDeviceID)
            elif self.outputDeviceID:
                dirpath = os.path.join(dirpath, self.outputDeviceID)
            os.makedirs(dirpath)
            filepath = os.path.join(dirpath, self.uuid)
            fp = open(filepath, 'w')
            fp.write(self.data)
            self.output(True)
            return
        else:
            assert 0, "Unknown operation %s" % self.op
        self.output(True)
        
    def output(self, yesno):
        print "Content-type: text/plain"
        print
        print "YES" if yesno else "NO"

uploader = Uploader()
uploader.run()
