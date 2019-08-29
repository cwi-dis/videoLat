//
//  NetworkOutputView.m
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkOutputView.h"

#ifdef WITH_UIKIT
// Gross....
#define stringValue text
#endif

@implementation NetworkOutputView
- (NSString *)deviceID
{
	return @"NetworkOutput";
}

- (NSString *)deviceName
{
	return @"NetworkOutput";
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
    NSLog(@"xxxjack NetworkOutputView: Assuming OK to switch to %@", name);
    return YES;
}


- (void) showNewData
{
    if (!self.networkDevice) {
        NSLog(@"NetworkOutputView.showNewData: ignoring, no networkDevice");
        return;
    }
    assert(self.networkDevice);
    [self.networkDevice showNewData];
}

- (BOOL)available {
	return YES;
}

- (void)stop {
}

- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
	NSLog(@"NetworkOutputView.reportServer ip=%@ port=%d isUs=%d", ip, port, us);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bPeerIPAddress.stringValue = ip;
        self.bPeerPort.stringValue = [NSString stringWithFormat:@"%d", port];
    });
}

- (void)reportRTT:(uint64_t)rtt  best:(uint64_t)best {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bPeerRTT.stringValue = [NSString stringWithFormat:@"%lld (best %lld)", rtt/1000, best/1000];
    });
}


- (void)reportStatus:(NSString * _Nonnull)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bNetworkStatus.stringValue = status;
    });
}

@end
