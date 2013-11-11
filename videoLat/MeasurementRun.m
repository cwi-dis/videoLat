//
//  MeasurementRun.m
//  videoLat
//
//  Created by Jack Jansen on 11/11/13.
//
//

#import "MeasurementRun.h"

@implementation MeasurementRun
@synthesize scenario;
@synthesize inputID;
@synthesize inputName;
@synthesize outputID;
@synthesize outputName;
@synthesize description;
@synthesize time;
@synthesize location;
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

- (MeasurementRun *) init
{
    self = [super init];
    scenario = nil;
    inputID = nil;
    inputName = nil;
    outputID = nil;
    outputName = nil;
    description = nil;
    time = nil;
    location = nil;
    
    sum = 0;
    sumSquares = 0;
    count = 0;
    
	store = [[NSMutableArray alloc] init];
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    scenario = [coder decodeObjectForKey: @"scenario"];
    inputID = [coder decodeObjectForKey: @"inputID"];
    inputName = [coder decodeObjectForKey: @"inputName"];
    outputID = [coder decodeObjectForKey: @"outputID"];
    outputName = [coder decodeObjectForKey: @"outputName"];
    description = [coder decodeObjectForKey: @"description"];
    time = [coder decodeObjectForKey: @"time"];
    location = [coder decodeObjectForKey: @"location"];
    
    sum = [coder decodeDoubleForKey:@"sum"];
    sumSquares = [coder decodeDoubleForKey:@"sumSquares"];
    count = [coder decodeIntForKey:@"count"];
    
    store = [coder decodeObjectForKey: @"store"];
    return self;
}
           
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:scenario forKey: @"scenario"];
    [coder encodeObject:inputID forKey: @"inputID"];
    [coder encodeObject:inputName forKey: @"inputName"];
    [coder encodeObject:outputID forKey: @"outputID"];
    [coder encodeObject:outputName forKey: @"outputName"];
    [coder encodeObject:description forKey: @"description"];
    [coder encodeObject:time forKey: @"time"];
    [coder encodeObject:location forKey: @"location"];

    [coder encodeDouble: sum forKey: @"sum"];
    [coder encodeDouble: sumSquares forKey: @"sumSquares"];
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

@end
