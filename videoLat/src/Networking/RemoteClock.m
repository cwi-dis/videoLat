//
//  NetworkProtocol.m
//  videoLat
//
//  Created by Jack Jansen on 02/10/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemoteClock.h"
#import "EventLogger.h"
#if 0
#import "NetworkProtocol.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#endif

/// Define this to always use the latest measurement as the correct time.
#undef WITH_TIMESYNC_LATEST
/// Define this to use the best measurement (shortest RTT) as the correct time.
#undef WITH_TIMESYNC_BEST
// Define this to use something of a running average
#define WITH_TIMESYNC_AVERAGE
#define AVERAGE_FACTOR 4

@implementation RemoteClock
- (RemoteClock *) init
{
	self = [super init];
	localTimeToRemoteTime = 0;
    initialized = false;
	return self;
}

- (uint64_t)remoteNow: (uint64_t) now
{
    if (!initialized) return 0;
	return now + localTimeToRemoteTime;
}

- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish
{
    if (finish < start) {
        NSLog(@"SimpleRemoteClock: local timeinterval start %lld > end %lld, assuming local NTP re-sync", start, finish);
        VL_LOG_EVENT(@"negativeRTT", start-finish, @"");
        return;
    }
	rtt = finish-start;
    VL_LOG_EVENT(@"RTT", rtt, @"");
	uint64_t mid = (finish+start)/2;
	uint64_t newLocalTimeToRemoteTime = (int64_t)remote - (int64_t)mid;
#if defined(WITH_TIMESYNC_BEST)
	if (rtt <= clockInterval || !initialized) {
		clockInterval = rtt;
		localTimeToRemoteTime = newLocalTimeToRemoteTime;
	}
#elif  defined(WITH_TIMESYNC_LATEST)
	clockInterval = rtt;
	localTimeToRemoteTime = newLocalTimeToRemoteTime;
#elif defined(WITH_TIMESYNC_AVERAGE)
    if (!initialized) {
        clockInterval = rtt;
        localTimeToRemoteTime = newLocalTimeToRemoteTime;
    } else {
        clockInterval = ((clockInterval*(AVERAGE_FACTOR-1))+rtt)/AVERAGE_FACTOR;
        localTimeToRemoteTime = ((localTimeToRemoteTime*(AVERAGE_FACTOR-1))+newLocalTimeToRemoteTime)/AVERAGE_FACTOR;
    }
#else
#error No timesync algorithm selected
#endif
    VL_LOG_EVENT(@"NewMasterTime", [self remoteNow: finish], @"");
    initialized = true;
}

- (uint64_t) rtt
{
    return rtt;
}

- (uint64_t) clockInterval
{
    return clockInterval;
}

@end

