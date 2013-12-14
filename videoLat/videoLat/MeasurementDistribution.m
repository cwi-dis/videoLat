//
//  MeasurementDistribution.m
//  videoLat
//
//  Created by Jack Jansen on 27/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "MeasurementDistribution.h"

@implementation MeasurementDistribution

- (double) average { return source.average; }
- (double) stddev { return source.stddev; }
- (double) maxXaxis { return source.max; }

- (MeasurementDistribution *) init
{
    self = [super init];
    if (self) {
        store = nil;
        source = nil;
        binCount = 100;
        binSize = 0;
    }
    return self;
}

- (MeasurementDistribution *)initWithSource: (MeasurementDataStore *)_source
{
    self = [self init];
    if (self) {
        [self setSource: _source];
    }
    return self;
}

- (void)awakeFromNib
{
    [self _recompute];
}

- (void)setSource: (id) _source
{
    source = _source;
    store = [[NSMutableArray alloc] initWithCapacity:binCount];
    for (int i=0; i<binCount; i++)
        [store addObject:[NSNumber numberWithDouble:0]];
    [self _recompute];
}

- (void)_recompute
{
    double sourceMin = source.min;
    double sourceMax = source.max;
    if (sourceMin > 0) sourceMin = 0; // For now we want distribution plots to start at 0.0
    binSize = (sourceMax - sourceMin) / (binCount-1);
    int sourceCount = source.count;
    for (int i=0; i < sourceCount; i++) {
        double value = [[source valueForIndex: i] doubleValue];
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
    double sourceMin = source.min;
    double sourceMax = source.max;
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
