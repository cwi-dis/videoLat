//
//  MeasurementDistribution.m
//  videoLat
//
//  Created by Jack Jansen on 27/11/13.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "MeasurementDistribution.h"

@implementation MeasurementDistribution

- (double) average { return self.source.average; }
- (double) stddev { return self.source.stddev; }
- (double) maxXaxis { return self.source.max; }
- (double) minXaxis { return self.source.min > 0 ? 0 : self.source.min; }
- (double) binSize { return binSize; }

- (MeasurementDistribution *) init
{
    self = [super init];
    if (self) {
        store = nil;
        binCount = 100;
        binSize = 0;
    }
    return self;
}

- (void) dealloc
{
}

- (MeasurementDistribution *)initWithSource: (MeasurementDataStore *)source
{
    self = [self init];
    if (self) {
        self.source = source;
		[self _recompute];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _recompute];
}

- (void)_recompute
{
	if (self.source == nil) return;
    store = [[NSMutableArray alloc] initWithCapacity:binCount];
    for (int i=0; i<binCount; i++)
        [store addObject:[NSNumber numberWithDouble:0]];
    double sourceMin = self.source.min;
    double sourceMax = self.source.max;
    if (sourceMin > 0) sourceMin = 0; // For now we want distribution plots to start at 0.0
    if (sourceMax <= sourceMin) sourceMax = sourceMin + 1;
    binSize = (sourceMax - sourceMin) / (binCount-1);
    int sourceCount = self.source.count;
    for (int i=0; i < sourceCount; i++) {
        double value = [[self.source valueForIndex: i] doubleValue];
        int binIndex = (int)((value-sourceMin) / binSize);
        double binValue = [[store objectAtIndex: binIndex] doubleValue];
        binValue += 1.0 / sourceCount;
        [store replaceObjectAtIndex:binIndex  withObject:[NSNumber numberWithDouble:binValue]];
    }
    
}

- (double) min
{
    return 0;
}

- (int) count
{
    return (int)[store count];
}

- (double) max
{
    double rv = 0;
    for (NSNumber *item in store) {
        double value = [item doubleValue];
        if (value > rv) rv = value;
    }
    return rv;
}

- (NSNumber *)valueForIndex: (int) i
{
    return [store objectAtIndex:i];
}
- (NSString *) asCSVString
{
	NSMutableString *rv;
	rv = [NSMutableString stringWithCapacity: 0];
	[rv appendString:@"lowerBound,upperBound,binValue\n"];
    double sourceMin = self.source.min;
    double sourceMax = self.source.max;
    if (sourceMin > 0) sourceMin = 0; // For now we want distribution plots to start at 0.0
    binSize = (sourceMax - sourceMin) / (binCount-1);
	double lwb = sourceMin;
    for (NSNumber *item in store) {
		double upb = lwb + binSize;
        double value = [item doubleValue];
		[rv appendFormat:@"%f,%f,%f\n", lwb, upb, value];
		lwb = upb;
	}
	return rv;
}


@end
