//
//  MeasurementRun.m
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import "MeasurementDataStore.h"

@implementation DeviceDescription
@synthesize location;
@synthesize machineTypeID;
@synthesize machineID;
@synthesize machine;
@synthesize deviceID;
@synthesize device;

@end

@implementation MeasurementDataStore
@synthesize measurementType;
@synthesize date;
@synthesize description;

@synthesize output;
@synthesize input;

@synthesize min;
@synthesize max;
@synthesize count;
@synthesize missCount;

- (NSString *)outputBaseMeasurementID {
    MeasurementDataStore *c = outputCalibration;
    if (c == nil) c = calibration;
	if (c == nil) return nil;
    return [NSString stringWithFormat:@"%@ (%@ to %@)", c.measurementType, c.output.device, c.input.device];
}

- (NSString *)inputBaseMeasurementID {
    MeasurementDataStore *c = inputCalibration;
    if (c == nil) c = calibration;
	if (c == nil) return nil;
    return [NSString stringWithFormat:@"%@ (%@ to %@)", c.measurementType, c.output.device, c.input.device];
}

- (double) baseMeasurementAverage {
    if (calibration) return calibration.average;
    return inputCalibration.average + outputCalibration.average;
}

- (double) baseMeasurementStddev {
    if (calibration) return calibration.stddev;
    return fmax(inputCalibration.stddev, outputCalibration.stddev);
}

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
    date = nil;
    description = nil;
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
	input = [[DeviceDescription alloc] init];
	output = [[DeviceDescription alloc] init];
    measurementType = [coder decodeObjectForKey: @"scenario"];
    date = [coder decodeObjectForKey: @"date"];
    description = [coder decodeObjectForKey: @"description"];
    
    input.location = [coder decodeObjectForKey:@"inputLocation"];
    input.machineTypeID = [coder decodeObjectForKey:@"inputMachineTypeID"];
    input.machineID = [coder decodeObjectForKey:@"inputMachineID"];
    input.machine = [coder decodeObjectForKey:@"inputMachine"];
    input.deviceID = [coder decodeObjectForKey: @"inputID"];
    input.device = [coder decodeObjectForKey: @"inputName"];
    
    output.location = [coder decodeObjectForKey:@"outputLocation"];
    output.machineTypeID = [coder decodeObjectForKey:@"outputMachineTypeID"];
    output.machineID = [coder decodeObjectForKey:@"outputMachineID"];
    output.machine = [coder decodeObjectForKey:@"outputMachine"];
    output.deviceID = [coder decodeObjectForKey: @"outputID"];
    output.device = [coder decodeObjectForKey: @"outputName"];

    sum = [coder decodeDoubleForKey:@"sum"];
    sumSquares = [coder decodeDoubleForKey:@"sumSquares"];
    min = [coder decodeDoubleForKey:@"min"];
    max = [coder decodeDoubleForKey:@"max"];
    count = [coder decodeIntForKey:@"count"];
    missCount = [coder decodeIntForKey:@"missCount"];

    calibration = [coder decodeObjectForKey: @"calibration"];
    inputCalibration = [coder decodeObjectForKey: @"inputCalibration"];
    outputCalibration = [coder decodeObjectForKey: @"outputCalibration"];
    
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
    
    [coder encodeObject:input.location forKey: @"inputLocation"];
    [coder encodeObject:input.machineTypeID forKey: @"inputMachineTypeID"];
    [coder encodeObject:input.machineID forKey: @"inputMachineID"];
    [coder encodeObject:input.machine forKey: @"inputMachine"];
    [coder encodeObject:input.deviceID forKey: @"inputID"];
    [coder encodeObject:input.device forKey: @"inputName"];
    
    [coder encodeObject:output.location forKey: @"outputLocation"];
    [coder encodeObject:output.machineTypeID forKey: @"outputMachineTypeID"];
    [coder encodeObject:output.machineID forKey: @"outputMachineID"];
    [coder encodeObject:output.machine forKey: @"outputMachine"];
    [coder encodeObject:output.deviceID forKey: @"outputID"];
    [coder encodeObject:output.device forKey: @"outputName"];

    [coder encodeDouble: sum forKey: @"sum"];
    [coder encodeDouble: sumSquares forKey: @"sumSquares"];
    [coder encodeDouble: min forKey: @"min"];
    [coder encodeDouble: max forKey: @"max"];
    [coder encodeInt: count forKey: @"count"];
    [coder encodeInt: missCount forKey: @"missCount"];

    [coder encodeObject: calibration forKey: @"calibration"];
    [coder encodeObject: inputCalibration forKey: @"inputCalibration"];
    [coder encodeObject: outputCalibration forKey: @"outputCalibration"];
    
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
    if (calibration || inputCalibration || outputCalibration) {
        NSLog(@"MeasurementDataStore: attempt to set calibration a second time");
        abort();
        return;
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
    if (calibration || inputCalibration) {
        NSLog(@"MeasurementDataStore: attempt to set calibration a second time");
        abort();
        return;
    }
    inputCalibration = _inputCalibration;
}

- (void)useOutputCalibration: (MeasurementDataStore *)_outputCalibration
{
    if (store && [store count]) {
        // Too late, data values entered already...
        NSLog(@"MeasurementDataStore: attempt to set calibration after data has been collected already! Programmer error...\n");
        abort();
        return;
    }
    if (calibration || outputCalibration) {
        NSLog(@"MeasurementDataStore: attempt to set calibration a second time");
        abort();
        return;
    }
    outputCalibration = _outputCalibration;
}

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received
{
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
    missCount++;	
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
