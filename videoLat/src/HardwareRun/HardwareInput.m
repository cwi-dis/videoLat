#import "HardwareInput.h"
#import "EventLogger.h"


@implementation HardwareInput
@synthesize deviceID;
@synthesize deviceName;

- (HardwareInput *)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
	[self stop];
}

- (void) awakeFromNib
{    
    [super awakeFromNib];
    
    // Setup for callbacks

	if (VL_DEBUG) NSLog(@"Devices: %@\n", [self deviceNames]);
}

- (uint64_t)now
{
    UInt64 timestamp;
	timestamp = monotonicMicroSecondClock();
    return timestamp;
}

- (void) stop
{
	assert(0);
}

- (bool)available
{
	assert(0);
	return true;
}

+ (NSArray*) deviceNames
{
	assert(0);
	NSMutableArray *rv = [NSMutableArray arrayWithCapacity:128];

	return rv;
}

- (NSArray *)deviceNames
{
	return [[self class] deviceNames];
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
	assert(0);
    return YES;
}

- (void)pauseCapturing: (BOOL) pause
{
	assert(0);
}

- (void) startCapturing: (BOOL) showPreview
{
	assert(0);
	capturing = YES;
}

- (void) stopCapturing
{
	assert(0);
	capturing = NO;
}

- (void)setMinCaptureInterval:(uint64_t)interval
{
	assert(0);
}

@end
