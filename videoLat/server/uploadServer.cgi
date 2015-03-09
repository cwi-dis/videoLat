#!/usr/bin/python
import cgi
import cgitb
import os
import sys
import plistlib

cgitb.enable()

# Directory structure:
# basedir/
#         blacklisted/
#                     247c5cd7-f4c1-4153-ba96-e86dc2088655 - Measurement that should not be uploaded (inspected, and faulty)
#         machineTypeID/
#                       deviceTypeID/
#                                    measurementTypeID/
#                                                      247c5cd7-f4c1-4153-ba96-e86dc2088655
BASEDIR=os.path.join(os.path.dirname(os.path.dirname(__file__)), "measurements")

class Uploader:
    def __init__(self):
        self.op = None
        self.uuid = None
        self.measurementTypeID = None
        self.machineTypeID = None
        self.deviceTypeID = None
        self.dataSize = None
        self.data = None
        self.pathname = None
        self.measurementTypeIDs = []
        self.machineTypeIDs = []
        self.deviceTypeIDs = []
        assert os.path.exists(BASEDIR)
        
    def parseArguments(self):
        if 'REQUEST_METHOD' in os.environ and os.environ['REQUEST_METHOD'] == 'PUT':
            os.environ['REQUEST_METHOD'] = 'GET'
        args = cgi.FieldStorage()
        self.op = args.getfirst('op', None)
        self.uuid = args.getfirst('uuid', None)
        self.measurementTypeID = args.getfirst('measurementTypeID', None)
        self.machineTypeID = args.getfirst('machineTypeID', None)
        self.deviceTypeID = args.getfirst('deviceTypeID', None)
        self.measurementTypeIDs = args.getlist('measurementTypeID')
        self.machineTypeIDs = args.getlist('machineTypeID')
        self.deviceTypeIDs = args.getlist('deviceTypeID')
        self.dataSize = args.getfirst('dataSize', None)
        assert self.op
        if self.dataSize:
            self.data = sys.stdin.read()
            dataSize = int(self.dataSize)
            assert len(self.data) == dataSize, "Expected %d bytes got %d bytes" % (dataSize, len(self.data))
        
    def run(self):
        self.parseArguments()
        if self.op == "check":
            self.runCheck()
        elif self.op == "upload":
            self.runUpload()
        elif self.op == "list":
            self.runList()
        elif self.op == "get":
            self.runGet()
        else:
            assert 0, "Unknown operation %s" % self.op

    def runCheck(self):
        assert self.uuid
        assert self.measurementTypeID
        assert self.machineTypeID
        assert self.deviceTypeID
        assert len(self.measurementTypeIDs) <= 1
        assert len(self.machineTypeIDs) <= 1
        assert len(self.deviceTypeIDs) <= 1
        assert self.data == None

        testpath = os.path.join(BASEDIR, 'blacklisted', self.uuid)
        if os.path.exists(testpath):
            self.outputBool(False)
            return
        testpath = os.path.join(BASEDIR, self.machineTypeID, self.deviceTypeID, self.measurementTypeID)
        if os.path.exists(os.path.join(testpath, self.uuid)):
            self.outputBool(False)
            return
        if os.path.exists(testpath):
            self.outputBool(False)
            return
        self.outputBool(True)
    
    def runUpload(self):
        assert self.uuid
        assert self.measurementTypeID
        assert self.machineTypeID
        assert self.deviceTypeID
        assert len(self.measurementTypeIDs) <= 1
        assert len(self.machineTypeIDs) <= 1
        assert len(self.deviceTypeIDs) <= 1
        assert self.data

        dirpath = os.path.join(BASEDIR, self.machineTypeID, self.deviceTypeID, self.measurementTypeID)
        os.makedirs(dirpath)
        filepath = os.path.join(dirpath, self.uuid)
        fp = open(filepath, 'w')
        fp.write(self.data)
        self.outputBool(True)
    
    def runList(self):
        rv = []
        curPaths = [BASEDIR]
        for nextPathChoices in [self.machineTypeIDs, self.deviceTypeIDs, self.measurementTypeIDs, []]:
            if not nextPathChoices:
                # No selection for this item, try everything
                nextPathChoices = []
                for cp in curPaths:
                    nextPathChoices += os.listdir(cp)
            nextPaths = []
            for cp in curPaths:
                for np in nextPathChoices:
                    candidate = os.path.join(cp, np)
                    if os.path.exists(candidate) and not candidate in nextPaths:
                        nextPaths.append(candidate)
            curPaths = nextPaths
        for item in curPaths:
            rest = item
            rest, uuid = os.path.split(item)
            rest, measurementTypeID = os.path.split(rest)
            rest, deviceTypeID = os.path.split(rest)
            rest, machineTypeID = os.path.split(rest)
            rv.append(dict(uuid=uuid, deviceTypeID=deviceTypeID, machineTypeID=machineTypeID, measurementTypeID=measurementTypeID))
        data = plistlib.writePlistToString(rv)
        print "Content-type: application/xml"
        print
        print data
                    
         
        
    def runGet(self):
        assert self.uuid
        assert self.measurementTypeID
        assert self.machineTypeID
        assert self.deviceTypeID
        filepath = os.path.join(BASEDIR, self.machineTypeID, self.deviceTypeID, self.measurementTypeID, self.uuid)
        data = open(filepath, 'rb').read()
        print "Content-type: application/x-plist"
        print
        print data
         
    def outputBool(self, yesno):
        print "Content-type: text/plain"
        print
        print "YES" if yesno else "NO"

uploader = Uploader()
uploader.run()
