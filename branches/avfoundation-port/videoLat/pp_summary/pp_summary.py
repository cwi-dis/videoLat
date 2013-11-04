import pstat
import stats
import csv
import sys
import os
import shutil
import time
from optparse import OptionParser

VERBOSE=True

class DataError(ValueError):
    pass
    
def opencsv(filename):
    """Open given filename as a csv-reader object"""
    data = open(filename).read(4096)
    dialect = csv.Sniffer().sniff(data)
    reader = csv.reader(open(filename), dialect)
    return reader

class Summary:
    """summarize raw videoLat output data into a frequency plot and a few
     useful statistics (min, max, average, etc)"""
     
    # How many frequency bins do we want in our frequence graph?
    NUMBER_OF_BINS=100
    
    # What are readable sizes for each bin (in microseconds)?
    STEPSIZES=[
        1,2,5,
        10, 20,50,
        100,200,500,
        1000,2000,5000,
        10000,20000,50000,
        100000,200000,500000,
        1000000,2000000,5000000]
    
    def __init__(self):
        self.xmit_times = {}
        self.recv_times = {}
        self.template = None
        # The event/subevent codes we are looking for:
        self.xmit_event = 'macVideoXmit'
        self.xmit_subevents = ['generated']
        self.recv_event = 'macVideoGrab'
        self.recv_subevents = ['data']
        
    def set_template(self, template):
        self.template = template
        
    def set_monochrome(self):
        self.xmit_event = 'blackWhiteXmit'
        self.xmit_subevents = ['black', 'white']
        self.recv_event = 'blackWhiteGrab'
        self.recv_subevents = ['black', 'white']
        
    def set_hwtransmit(self):
        self.xmit_event = 'hardwareXmit'
        
    def set_hwreceive(self):
        self.recv_event = 'hardwareGrab'
        
    def read_xmit_times(self, filename):
        """Read the videoLat output file containing the transmission timestamps"""
        reader = opencsv(filename)
        for row in reader:
            self.process_xmit_time(row)
        
    def process_xmit_time(self, row):
        """Process a single transmission timestamp line"""
        if len(row) >= 6 and row[1] == self.xmit_event and row[2] in self.xmit_subevents:
            timestamp = int(row[0])
            data = row[3]
            if row[4] == 'overhead':
                overhead = int(row[5])
                timestamp += overhead
            if data in self.xmit_times:
                print "Duplicate transmitted code:", data
                # XXXX? raise DataError, 'Duplicate transmitted code: %s' % data
                pass
            else:
                self.xmit_times[data] = timestamp
                if VERBOSE:
                    print "Transmitted",data,"at",timestamp
            
    def read_recv_times(self, filename):
        """Read the videoLat output file containing the transmission timestamps"""
        reader = opencsv(filename)
        for row in reader:
            self.process_recv_time(row)
        
    def process_recv_time(self, row):
        if len(row) >= 6 and row[1] == self.recv_event and row[2] in self.recv_subevents:
            timestamp = int(row[0])
            data = row[3]
            if row[4] == 'overhead':
                overhead = int(row[5])
                timestamp -= overhead
            if not data in self.recv_times:
                self.recv_times[data] = timestamp
                if VERBOSE:
                    print "Received",data,"at",timestamp
            else:
                if VERBOSE:
                    print "Received duplicate",data,"at",timestamp
                
    def measurement_delays(self):
        delays = []
        for data, recvtime in self.recv_times.items():
            if not data in self.xmit_times:
                if self.recv_event == 'hardwareGrab':
                    print 'Skip spurious hardware detection:', data
                    continue
                raise DataError, 'Detected non-transmitted code: %s' % data
            xmittime = self.xmit_times[data]
            delays.append((data, recvtime - xmittime))
        return delays
        
    def delays(self):
        return map(lambda x:x[1], self.measurement_delays())
        
    def gen_summary(self, filename):
        delays = self.delays()
        delays.sort()
        boundary_cut_count = len(delays)/20
        if boundary_cut_count:
            delays = delays[boundary_cut_count:-boundary_cut_count]
        if VERBOSE:
            print 'Delays:', delays
        if not delays:
            sys.exit(1)
        fp = open(filename, 'w')
        fp.write('count,min,max,mean,stddev\n')
        mean = stats.lmean(delays)
        stddev = stats.lsamplestdev(delays)
        ndelays, mindelay, maxdelay = len(delays),min(delays), max(delays)
        fp.write('%s,%s,%s,%s,%s\n' % (ndelays, mindelay, maxdelay, mean, stddev))
        fp.write('\n')
        fp.write('bin,lwbound,upbound,fraction,cumfraction\n')
        
        # Find reasonable bounds
        stepsize = (maxdelay-mindelay) / self.NUMBER_OF_BINS
        for rounded_stepsize in self.STEPSIZES:
            if rounded_stepsize > stepsize:
                stepsize = rounded_stepsize
                break
        headroom = (stepsize*self.NUMBER_OF_BINS) - (maxdelay-mindelay)
        assert headroom >= 0
        lwb = int((mindelay-headroom/2)/stepsize)*stepsize
        upb = lwb + self.NUMBER_OF_BINS*stepsize
        assert lwb <= mindelay
        assert upb >= maxdelay
        hist, lwbound, dbound, _ = stats.lrelfreq(delays, self.NUMBER_OF_BINS, [lwb, upb])
        bin = 0
        cum = 0
        for fraction in hist:
            upbound = lwbound + dbound
            cum += fraction
            fp.write('%s,%s,%s,%s,%s\n' % (bin, lwbound, upbound, fraction, cum))
            lwbound = upbound
            bin += 1
            
    def gen_measurements(self, filename):
        delays = self.measurement_delays()
        delays = map(lambda x: (int(x[0]), int(x[1])), delays)
        delays.sort()
        fp = open(filename, 'w')
        fp.write('measurement,delay\n')
        for  measurement, delay in delays:
            fp.write("%s,%s\n" % (measurement, delay))
            
    def merge_template(self, summary, measurements, graph):
        if VERBOSE:
            print 'Opening', summary, 'with Numbers'
        rv = os.system("open -a Numbers '%s'" % summary)
        if rv:
            print 'open -a Numbers returned status %d' % rv
            sys.exit(rv)
            
        if VERBOSE:
            print 'Opening', measurements, 'with Numbers'
        rv = os.system("open -a Numbers '%s'" % measurements)
        if rv:
            print 'open -a Numbers returned status %d' % rv
            sys.exit(rv)
            

        if self.template:
            shutil.copy(self.template, graph)
            time.sleep(5)
            if VERBOSE:
                print 'Opening', graph, 'with Numbers'
            rv = os.system("open -a Numbers '%s'" % graph)
            if rv:
                print 'open -a Numbers returned status %d' % rv
            
    def process_single_file(self, filename):
        basefilename, ext = os.path.splitext(filename)
        outfilename = basefilename + '-summary' + ext
        outgraphfilename = basefilename + '-summary-graph.numbers'
        measurementfilename = basefilename + '-measurements' + ext
        self.read_xmit_times(filename)
        self.read_recv_times(filename)
        if VERBOSE:
            print "Found", len(self.xmit_times),"transmitted codes,",len(self.recv_times),"received codes"
        self.gen_summary(outfilename)
        if VERBOSE:
            print 'Output written to', outfilename
        self.gen_measurements(measurementfilename)
        if VERBOSE:
            print 'Measurements written to', measurementfilename
        self.merge_template(outfilename, measurementfilename, outgraphfilename)
        
def main():
    parser = OptionParser(usage="Usage: %prog [options] csvfile [...]")
    parser.add_option("-t", "--template", dest="template",
        metavar="FILE", help="merge summary data into template FILE")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true",
        help="verbose messages during processing")
    parser.add_option("-m", "--monochrome", dest="monochrome", action="store_true",
        help="detect monochrome, not QRcodes")
    parser.add_option("-R", "--hwreceive", dest="hwreceive", action="store_true",
        help="use hardware monochrome detection")
    parser.add_option("-X", "--hwtransmit", dest="hwtransmit", action="store_true",
        help="use hardware monochrome transmission")
    opts, args = parser.parse_args()
    if not args:
        parser.print_help()
        sys.exit(1)

    worker = Summary()
    if opts.template:
        worker.set_template(opts.template)
    if opts.hwtransmit or opts.hwreceive:
        opts.monochrome = True
    if opts.monochrome:
        worker.set_monochrome()
    if opts.hwtransmit:
        worker.set_hwtransmit()
    if opts.hwreceive:
        worker.set_hwreceive()
    global VERBOSE
    VERBOSE = opts.verbose

    for arg in args:
        worker.process_single_file(arg)
    
if __name__ == '__main__':
    main()
    
    