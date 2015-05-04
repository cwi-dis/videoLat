#import "NetworkInput.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

@implementation NetworkInput

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
	assert(0);
}

- (NetworkInput *)init
{
    self = [super init];
    if (self) {
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
//		if (CMClockGetHostTimeClock != NULL) {
//			clock = CMClockGetHostTimeClock();
//		}
#endif
    }
    return self;
}

- (void)dealloc
{
	[self stop];
}

- (void) awakeFromNib
{    
}

- (uint64_t)now
{
    return monotonicMicroSecondClock();
}

- (void) stop
{

}

- (void)setMinCaptureInterval: (uint64_t)interval
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

- (void) pauseCapturing:(BOOL)pause
{
}

@end
