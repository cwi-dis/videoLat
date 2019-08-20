///
///  @file NetworkProtocol.h
///  @brief Protocol to allow two videoLat instances to communicate.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// Object that tracks a remote clock, by keeping track of RTT values.
///
@interface RemoteClock : NSObject {
	int64_t localTimeToRemoteTime;
	uint64_t clockInterval;
    uint64_t rtt;
    bool initialized;
};

/// Convert local time to remote time.
/// @param now Local time in microseconds
/// @return Remote time in microseconds
- (uint64_t)remoteNow: (uint64_t) now;

/// Add measurement of round-trip delay to update local-to-remote time mapping.
/// @param remote Remote clock time reported in the reply packet
/// @param start Local clock time we sent the request packet
/// @param finish Local clock time we received the reply packet
- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;

/// Return round-trip-time.
/// @return Current round trip time
- (uint64_t)rtt;

/// Return rtt used to determine current clock synchronization.
/// @return Best rtt measured
- (uint64_t)clockInterval;
@end

@protocol RemoteClockProtocol

- (uint64_t)remoteNow: (uint64_t) now;

- (void)remote: (uint64_t)remote between: (uint64_t)start and: (uint64_t) finish;

- (uint64_t)rtt;

- (uint64_t)clockInterval;
@end
