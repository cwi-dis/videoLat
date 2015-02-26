#import "NetworkInput.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

@implementation NetworkInput
- (NSString *)deviceID
{
    return @"NetworkInput";
}

- (NSString *)deviceName
{
    return @"NetworkInput";
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
    UInt64 timestamp;
#if 0 && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
    if (clock) {
        CMTime timestampCMT = CMClockGetTime(clock);
        timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
        timestamp = timestampCMT.value;
    } else
#endif
	{
		clock_serv_t cclock;
		mach_timespec_t mts;

		host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
		clock_get_time(cclock, &mts);
		mach_port_deallocate(mach_task_self(), cclock);
		timestamp = ((UInt64)mts.tv_sec*1000000LL) + mts.tv_nsec/1000LL;
    }
    return timestamp;
}

- (void) stop
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
@end
