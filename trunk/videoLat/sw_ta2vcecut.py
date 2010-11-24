print "Hello World"
import sys
print 'sys.path=', sys.path
import xmlrpclib

VCEADDRESS = "http://localhost:8008"
vce = xmlrpclib.ServerProxy(VCEADDRESS)
# Check that we can talk to it
vce.CutToCamera(1)

toggle = 1

def newOutput(str):
	global toggle
	#print "Python newOutput:", str
	toggle = not toggle
	if toggle:
		vce.CutToCamera(2)
		return "999888777666"
	else:
		vce.CutToCamera(1)
	
def newBWOutput(bool):
	#print "Python newBWOutput:", bool
	pass
