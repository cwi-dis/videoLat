import pstat
import stats
import csv
import sys
import os

VERBOSE=False

class DataError(ValueError):
    pass
    
def opencsv(filename):
    """Open given filename as a csv-reader object"""
    data = open(filename).read(4096)
    dialect = csv.Sniffer().sniff(data)
    reader = csv.reader(open(filename), dialect)
    return reader

class Summary:
    NUMBER_OF_BINS=100
    STEPSIZES=[1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000]
    
    def __init__(self):
        self.xmit_times = {}
        self.recv_times = {}
        
    def read_xmit_times(self, filename):
        reader = opencsv(filename)
        for row in reader:
            self.process_xmit_time(row)
        
    def process_xmit_time(self, row):
        if len(row) >= 6 and row[1] == 'macVideoXmit' and row[2] == 'generated':
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
        reader = opencsv(filename)
        for row in reader:
            self.process_recv_time(row)
        
    def process_recv_time(self, row):
        if len(row) >= 6 and row[1] == 'macVideoGrab' and row[2] == 'data':
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
                
    def delays(self):
        delays = []
        for data, recvtime in self.recv_times.items():
            if not data in self.xmit_times:
                raise DataError, 'Detected non-transmitted code: %s' % data
            xmittime = self.xmit_times[data]
            delays.append(recvtime - xmittime)
        return delays
        
    def gen_summary(self, filename):
        delays = self.delays()
        delays.sort()
        boundary_cut_count = len(delays)/20
        delays = delays[boundary_cut_count:-boundary_cut_count]
        if VERBOSE:
            print 'Delays:', delays
        if not delays:
            sys.exit(1)
        fp = open(filename, 'w')
        fp.write('count,min,max,mean,stddev\n')
        mean = stats.lmean(delays)
        stddev = stats.lsamplestdev(delays)
        fp.write('%s,%s,%s,%s,%s\n' % (len(delays),min(delays), max(delays), mean, stddev))
        fp.write('\n')
        fp.write('bin,lwbound,upbound,fraction,cumfraction\n')
        
        # Find reasonable bounds
        stepsize = (max(delays)-min(delays)) / self.NUMBER_OF_BINS
        for rounded_stepsize in self.STEPSIZES:
            if rounded_stepsize > stepsize:
                stepsize = rounded_stepsize
                break
        lwb = int(min(delays)/stepsize)*stepsize
        upb = lwb + self.NUMBER_OF_BINS*stepsize
        assert lwb <= min(delays)
        assert upb >= max(delays)
        hist, lwbound, dbound, _ = stats.lrelfreq(delays, self.NUMBER_OF_BINS, [lwb, upb])
        bin = 0
        cum = 0
        for fraction in hist:
            upbound = lwbound + dbound
            cum += fraction
            fp.write('%s,%s,%s,%s,%s\n' % (bin, lwbound, upbound, fraction, cum))
            lwbound = upbound
            bin += 1
            
    def process_single_file(self, filename):
        basefilename, ext = os.path.splitext(filename)
        outfilename = basefilename + '-summary' + ext
        self.read_xmit_times(filename)
        self.read_recv_times(filename)
        if VERBOSE:
            print "Found", len(self.xmit_times),"transmitted codes,",len(self.recv_times),"received codes"
        self.gen_summary(outfilename)
        if VERBOSE:
            print 'Output written to', outfilename
        rv = os.system("open -a Numbers '%s'" % outfilename)
        if rv:
            print 'open -a Numbers returned status %d' % rv
            sys.exit(rv)
        
def main():
    if len(sys.argv) != 2:
        print 'Usage: %s csvfile' % sys.argv[0]
        sys.exit(1)
    worker = Summary()
    worker.process_single_file(sys.argv[1])
    
if __name__ == '__main__':
    main()
    
    