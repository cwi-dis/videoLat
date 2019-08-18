//
//  MeasurementRun.m
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import "MeasurementDataStore.h"
#import "MeasurementType.h"
#import "EventLogger.h"

@implementation MeasurementDataStore
@synthesize measurementType;
@synthesize date;
@synthesize description;
@synthesize uuid;

@synthesize output;
@synthesize input;

@synthesize min;
@synthesize max;
@synthesize count;
@synthesize missCount;

- (BOOL) hasSeparateCalibrations
{
	return (calibration == nil);
}

- (MeasurementDataStore *)outputCalibration {
    MeasurementDataStore *c = output.calibration;
    if (c == nil) c = calibration;
    return c;
}

- (MeasurementDataStore *)inputCalibration {
    MeasurementDataStore *c = input.calibration;
    if (c == nil) c = calibration;
    return c;
}

- (NSString *)descriptiveName {
    return [NSString stringWithFormat:@"%@ (%@ to %@)", self.measurementType, self.output.device, self.input.device];
}

- (BOOL)isCalibration
{
    MeasurementType *theType = [MeasurementType forType: measurementType];
    return theType.isCalibration;
}

- (NSString *)defaultNameForDocument
{
    MeasurementType *theType = [MeasurementType forType: measurementType];
    if (!theType.isCalibration) {
		// If this is an ordinary measurement data and time is probably best
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		NSDate *docDate = [formatter dateFromString:date];
		if (docDate == nil)
			docDate = [NSDate date];

		[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
		return [formatter stringFromDate:[NSDate date]];
	}
	NSString *name;
	if (theType.inputOnlyCalibration) {
		name = [NSString stringWithFormat:@"%@ (from %@)", self.input.nameForDevice, self.output.nameForDevice];

	} else if (theType.outputOnlyCalibration) {
		name = [NSString stringWithFormat:@"%@ (from %@)", self.output.nameForDevice, self.input.nameForDevice];
	} else {
		name = [NSString stringWithFormat:@"%@ to %@", self.output.nameForDevice, self.input.nameForDevice];
	}
	return name;
}

- (NSString *)defaultExtensionForDocument
{
    NSString *extension = @"videoLat";
    if (self.isCalibration) extension = @"vlCalibration";
	return extension;
}

- (NSString *)outputBaseMeasurementID {
    MeasurementDataStore *c = self.outputCalibration;
    if (c == nil) return nil;
    return [NSString stringWithFormat:@"%@ (%@ to %@)", c.measurementType, c.output.device, c.input.device];
}

- (NSString *)inputBaseMeasurementID {
    MeasurementDataStore *c = self.inputCalibration;
    if (c == nil) return nil;
    return [NSString stringWithFormat:@"%@ (%@ to %@)", c.measurementType, c.output.device, c.input.device];
}

- (double) baseMeasurementAverage {
    if (calibration) return calibration.average;
	if(input.calibration || output.calibration) {
		// If either input (or output) is a roundtrip measurement we must compensate.
		// Our best guess is halving the number.
		// NOTE: this is statistically unsafe, and should only be used if the numbers
		// are small. This is generally the case for hardware base measurements (and
		// possibly for audio measurements.
		double inputAverage = input.calibration.average;
		double outputAverage = output.calibration.average;
		return inputAverage + outputAverage;
	}
	return 0;
}

- (double) baseMeasurementStddev {
    if (calibration) return calibration.stddev;
	if(input.calibration || output.calibration) return fmax(input.calibration.stddev, output.calibration.stddev);
	return 0;
}

- (double) maxXaxis
{
    return count;
}

- (double) minXaxis
{
	return 0;
}

- (double) binSize
{
	return 1;
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
    date = nil;
    description = nil;
    uuid = [[NSUUID UUID] UUIDString];
	input = [[DeviceDescription alloc] init];
	output = [[DeviceDescription alloc] init];

    sum = 0;
    sumSquares = 0;
    count = 0;
	missCount = 0;
    
	store = [[NSMutableArray alloc] init];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    measurementType = [coder decodeObjectForKey: @"scenario"];
    date = [coder decodeObjectForKey: @"date"];
    description = [coder decodeObjectForKey: @"description"];
    uuid = [coder decodeObjectForKey:@"uuid"];
    if (uuid == nil) uuid = [[NSUUID UUID] UUIDString];
    
    input = [coder decodeObjectForKey:@"input"];
    output = [coder decodeObjectForKey:@"output"];
    calibration = [coder decodeObjectForKey: @"calibration"];

    sum = [coder decodeDoubleForKey:@"sum"];
    sumSquares = [coder decodeDoubleForKey:@"sumSquares"];
    min = [coder decodeDoubleForKey:@"min"];
    max = [coder decodeDoubleForKey:@"max"];
    count = [coder decodeIntForKey:@"count"];
    missCount = [coder decodeIntForKey:@"missCount"];


    store = [coder decodeObjectForKey: @"store"];
    return self;
}

- (void) dealloc
{
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:measurementType forKey: @"scenario"];
    [coder encodeObject:date forKey: @"date"];
    [coder encodeObject:description forKey: @"description"];
    [coder encodeObject:uuid forKey: @"uuid"];
    
    [coder encodeObject:input forKey: @"input"];
    [coder encodeObject:output forKey: @"output"];
    [coder encodeObject: calibration forKey: @"calibration"];

    [coder encodeDouble: sum forKey: @"sum"];
    [coder encodeDouble: sumSquares forKey: @"sumSquares"];
    [coder encodeDouble: min forKey: @"min"];
    [coder encodeDouble: max forKey: @"max"];
    [coder encodeInt: count forKey: @"count"];
    [coder encodeInt: missCount forKey: @"missCount"];


    [coder encodeObject:store forKey: @"store"];
}

- (void)useCalibration: (MeasurementDataStore *)_calibration
{
    if (store && [store count]) {
        // Too late, data values entered already...
        NSLog(@"MeasurementDataStore: attempt to set calibration after data has been collected already! Programmer error...\n");
        abort();
        return;
    }
    if (calibration || input.calibration || output.calibration) {
        NSLog(@"MeasurementDataStore: warning: set calibration a second time");
    }
    calibration = _calibration;
}

- (void)useInputCalibration: (MeasurementDataStore *)_inputCalibration
{
    if (store && [store count]) {
        // Too late, data values entered already...
        NSLog(@"MeasurementDataStore: attempt to set calibration after data has been collected already! Programmer error...\n");
        abort();
        return;
    }
    if (calibration || input.calibration) {
        NSLog(@"MeasurementDataStore: attempt to set calibration a second time");
        abort();
        return;
    }
    input.calibration = _inputCalibration;
}

- (void)useOutputCalibration: (MeasurementDataStore *)_outputCalibration
{
    if (store && [store count]) {
        // Too late, data values entered already...
        NSLog(@"MeasurementDataStore: attempt to set calibration after data has been collected already! Programmer error...\n");
        abort();
        return;
    }
    if (calibration || output.calibration) {
        NSLog(@"MeasurementDataStore: attempt to set calibration a second time");
        abort();
        return;
    }
    output.calibration = _outputCalibration;
}

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received
{
	assert(!isTrimmed);
	if ([store count] == 0) {
		// First datapoint added.
		VL_LOG_EVENT(@"baseAverageToSubtract", self.baseMeasurementAverage, @"");
		NSLog(@"MeasurementDataStore: will subtract base measurement average %f µS", self.baseMeasurementAverage);
	}
	int64_t delay = received - sent;
	delay -= (int64_t)self.baseMeasurementAverage;
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

- (void) addMissingDataPoint: (NSString*) data sent: (uint64_t)sent
{
	assert(!isTrimmed);
    missCount++;	
}

- (void) trim
{
    if (count == 0) return;
	if (isTrimmed) return;
	isTrimmed = YES;
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
