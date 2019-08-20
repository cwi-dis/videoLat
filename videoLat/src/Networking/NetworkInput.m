#import "NetworkInput.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

@implementation NetworkInput

- (NetworkInput *)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.manager);
    if (self.outputManager == nil) self.outputManager = self.manager;
    if (self.clock == nil) self.clock = self;
}

- (void)dealloc
{
    [self stop];
}

- (uint64_t)now
{
    UInt64 timestamp;
    timestamp = monotonicMicroSecondClock();
    return timestamp;
}

- (BOOL)available {
	return YES; // xxxjack or should we test this?
}

- (NSArray *)deviceNames
{
    return @[];
}

- (NSString *)deviceID
{
    return @"NetworkInput";
}

- (NSString *)deviceName
{
    return @"NetworkInput";
}

- (BOOL)switchToDeviceWithName:(NSString *)name
{
	assert([name isEqualToString:@"NetworkInput"]);
    return true;
}

- (void) pauseCapturing:(BOOL)pause
{
}

- (void) startCapturing: (BOOL) showPreview
{
//	capturing = YES;
}

- (void) stopCapturing
{
//	capturing = NO;
}

- (void)setMinCaptureInterval: (uint64_t)interval
{
}

- (void) restart
{
}

- (void) stop
{
}

- (void)setOutputCode: (NSString *)newValue report: (BOOL)report
{
#if 0
    assert(alive);
    outputCode = newValue;
    newOutputValueWanted = YES;
    reportNewOutput = report;
#endif
}

@end
