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
@synthesize inputDeviceID;
@synthesize inputDevice;
@synthesize outputDeviceID;
@synthesize outputDevice;
@synthesize min;
@synthesize max;
@synthesize count;

- (double) average
{
    return sum / count;
}

- (double) stddev
{
    double average = sum / count;
    double variance = (sumSquares / count) - (average*average);
    return sqrt(variance);
}

- (MeasurementDataStore *) init
{
    self = [super init];
    measurementType = nil;
    inputDeviceID = nil;
    inputDevice = nil;
    outputDeviceID = nil;
    outputDevice = nil;

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
    inputDeviceID = [coder decodeObjectForKey: @"inputID"];
    inputDevice = [coder decodeObjectForKey: @"inputName"];
    outputDeviceID = [coder decodeObjectForKey: @"outputID"];
    outputDevice = [coder decodeObjectForKey: @"outputName"];
#if 0
    description = [coder decodeObjectForKey: @"description"];
    time = [coder decodeObjectForKey: @"time"];
    location = [coder decodeObjectForKey: @"location"];
#endif
    sum = [coder decodeDoubleForKey:@"sum"];
    sumSquares = [coder decodeDoubleForKey:@"sumSquares"];
    min = [coder decodeDoubleForKey:@"min"];
    max = [coder decodeDoubleForKey:@"max"];
    count = [coder decodeIntForKey:@"count"];
    
    store = [coder decodeObjectForKey: @"store"];
    return self;
}
           
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:measurementType forKey: @"scenario"];
    [coder encodeObject:inputDeviceID forKey: @"inputID"];
    [coder encodeObject:inputDevice forKey: @"inputName"];
    [coder encodeObject:outputDeviceID forKey: @"outputID"];
    [coder encodeObject:outputDevice forKey: @"outputName"];
#if 0
    [coder encodeObject:description forKey: @"description"];
    [coder encodeObject:time forKey: @"time"];
    [coder encodeObject:location forKey: @"location"];
#endif

    [coder encodeDouble: sum forKey: @"sum"];
    [coder encodeDouble: sumSquares forKey: @"sumSquares"];
    [coder encodeDouble: min forKey: @"min"];
    [coder encodeDouble: max forKey: @"max"];
    [coder encodeInt: count forKey: @"count"];

    [coder encodeObject:store forKey: @"store"];
}

- (void) addDataPoint: (NSString*) data sent: (uint64_t)sent received: (uint64_t) received
{
	uint64_t delay = received - sent;
    sum += delay;
    sumSquares += (delay * delay);
    if (count == 0 || delay < min) min = delay;
    if (count == 0 || delay > max) max = delay;
    count++;
    NSLog(@"%d %@ %lld-%lld=%lld  µ %f sd %f\n", count, data, received, sent, delay, self.average, self.stddev);
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
		uint64_t delay = [[item objectForKey:@"delay"] longLongValue];
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
	return [[store objectAtIndex:i] objectForKey:@"delay"];
}
@end

@implementation MeasurementDistribution

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
    sourceMin = 0; // For now we want distribution plots to start at 0.0
    binSize = (sourceMax - sourceMin) / (binCount-1);
    int sourceCount = source.count;
    for (int i=0; i < sourceCount; i++) {
        double value = [[source valueForIndex: i] doubleValue];
        int binIndex = (int)(value / binSize);
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
@end
