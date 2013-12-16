//
//  MeasurementRun.m
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import "MeasurementDataStore.h"

@implementation MeasurementDataStore
@synthesize measurementType;
@synthesize machineID;
@synthesize machine;
@synthesize inputDeviceID;
@synthesize inputDevice;
@synthesize outputDeviceID;
@synthesize outputDevice;
@synthesize min;
@synthesize max;
@synthesize count;
@synthesize baseMeasurementID;
@synthesize baseMeasurementAverage;
@synthesize baseMeasurementStddev;

- (double) maxXaxis
{
    return count;
}

- (double) average
{
    double rv = sum / count;
	return rv;
}

- (double) stddev
{
    double average = sum / count;
    double variance = (sumSquares / count) - (average*average);
#if 0
	// I think this is wrong, on second thought....
	variance += baseMeasurementStddev*baseMeasurementStddev;
#endif
    return sqrt(variance);
}

- (MeasurementDataStore *) init
{
    self = [super init];
    measurementType = nil;
    machineID = nil;
    machine = nil;
    inputDeviceID = nil;
    inputDevice = nil;
    outputDeviceID = nil;
    outputDevice = nil;

	baseMeasurementAverage = 0;
	baseMeasurementID = nil;
	baseMeasurementStddev = 0;

    sum = 0;
    sumSquares = 0;
    count = 0;
    
	store = [[NSMutableArray alloc] init];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    measurementType = [coder decodeObjectForKey: @"scenario"];
    machineID = [coder decodeObjectForKey: @"machineID"];
    machine = [coder decodeObjectForKey: @"machineName"];
    inputDeviceID = [coder decodeObjectForKey: @"inputID"];
    inputDevice = [coder decodeObjectForKey: @"inputName"];
    outputDeviceID = [coder decodeObjectForKey: @"outputID"];
    outputDevice = [coder decodeObjectForKey: @"outputName"];
    sum = [coder decodeDoubleForKey:@"sum"];
    sumSquares = [coder decodeDoubleForKey:@"sumSquares"];
    min = [coder decodeDoubleForKey:@"min"];
    max = [coder decodeDoubleForKey:@"max"];
    count = [coder decodeIntForKey:@"count"];

	baseMeasurementAverage = [coder decodeDoubleForKey:@"baseMeasurementAverage"];
	baseMeasurementStddev = [coder decodeDoubleForKey:@"baseMeasurementStddev"];
	baseMeasurementID = [coder decodeObjectForKey: @"baseMeasurementID"];
    
    store = [coder decodeObjectForKey: @"store"];
    return self;
}

- (void) dealloc
{
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:measurementType forKey: @"scenario"];
    [coder encodeObject:machineID forKey: @"machineID"];
    [coder encodeObject:machine forKey: @"machineName"];
    [coder encodeObject:inputDeviceID forKey: @"inputID"];
    [coder encodeObject:inputDevice forKey: @"inputName"];
    [coder encodeObject:outputDeviceID forKey: @"outputID"];
    [coder encodeObject:outputDevice forKey: @"outputName"];
    [coder encodeDouble: baseMeasurementAverage forKey: @"baseMeasurementAverage"];
    [coder encodeDouble: baseMeasurementStddev forKey: @"baseMeasurementStddev"];
    [coder encodeObject: baseMeasurementID forKey: @"baseMeasurementID"];

    [coder encodeDouble: sum forKey: @"sum"];
    [coder encodeDouble: sumSquares forKey: @"sumSquares"];
    [coder encodeDouble: min forKey: @"min"];
    [coder encodeDouble: max forKey: @"max"];
    [coder encodeInt: count forKey: @"count"];

    [coder encodeObject:store forKey: @"store"];
}

- (void)useCalibration: (MeasurementDataStore *)calibration
{
	if (store && [store count]) {
		// Too late, data values entered already...
		NSLog(@"MeasurementDataStore: attempt to set calibration after data has been collected already! Programmer error...\n");
		abort();
		return;
	}
	baseMeasurementAverage = calibration.average;
	baseMeasurementStddev = calibration.stddev;
	baseMeasurementID = [NSString stringWithFormat:@"%@ (%@ to %@)", calibration.measurementType, calibration.outputDevice, calibration.inputDevice];
}

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received
{
	int64_t delay = received - sent;
	delay -= (int64_t)baseMeasurementAverage;
    sum += delay;
    sumSquares += (delay * delay);
    if (count == 0 || delay < min) min = delay;
    if (count == 0 || delay > max) max = delay;
    count++;
    if (VL_DEBUG) NSLog(@"%d %@ %lld-%lld=%lld  µ %f sd %f\n", count, data, received, sent, delay, self.average, self.stddev);
	NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
		data, @"data",
		[NSNumber numberWithLongLong: received], @"at",
		[NSNumber numberWithLongLong: delay], @"delay",
		nil];
	[store addObject: item];
	
}

- (void) trim
{
    if (count == 0) return;
	// Sort by delay
	NSArray *trimmed = [store sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 objectForKey:@"delay"] compare: [obj2 objectForKey:@"delay"]];
	}];

	// Trim 5% at each end
	int arrayCount = (int)[trimmed count];
	if (arrayCount != count) NSLog(@"trim: count=%d but array size = %d!", count, arrayCount);
	int trimCount = arrayCount / 20;
	NSRange range;
	range.location = trimCount;
	range.length = count - 2*trimCount;
	trimmed = [trimmed subarrayWithRange: range];

	// Sort by time again
	trimmed = [trimmed sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 objectForKey:@"at"] compare: [obj2 objectForKey:@"at"]];
	}];

	// Put back into store and recompute sum and such
	store = [NSMutableArray arrayWithArray:trimmed];
	sum = 0;
	sumSquares = 0;
	count = (int)[store count];
	min = max = [[[store objectAtIndex:0] objectForKey:@"delay"] longLongValue];
	for (NSDictionary *item in store) {
		int64_t delay = [[item objectForKey:@"delay"] longLongValue];
		sum += delay;
		sumSquares += (delay * delay);
		if (delay < min) min = delay;
		if (delay > max) max = delay;
	}
}

- (NSString *) asCSVString
{
	NSMutableString *rv;
	rv = [NSMutableString stringWithCapacity: 0];
	[rv appendString:@"at,data,delay\n"];
	for (NSDictionary *item in store) {
		[rv appendFormat: @"%@,%@,%@\n", [item objectForKey:@"at"], [item objectForKey:@"data"], [item objectForKey:@"delay"]];
	}
	return rv;
}

- (NSNumber *)valueForIndex: (int) i
{
	NSNumber *delay = [[store objectAtIndex:i] objectForKey:@"delay"];
	return delay;
}
@end
