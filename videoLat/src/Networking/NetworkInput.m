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


- (BOOL)available {
	return YES; // xxxjack or should we test this?
}

- (BOOL)switchToDeviceWithName:(NSString *)name
{
	assert([name isEqualToString:@"NetworkInput"]);
    return true;
}

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
}

- (void)dealloc
{
	[self stop];
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
