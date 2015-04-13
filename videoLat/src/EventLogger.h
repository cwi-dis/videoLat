//
//  EventLogger.h
//  videoLat
//
//  Created by Jack Jansen on 10/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#define WITH_LOGGING

#ifdef WITH_LOGGING

@interface EventLogger : NSObject
{
	FILE *fp;
}

+ (EventLogger *)sharedLogger;

- (void) log: (NSString *)event from: (NSString *)module timestamp: (uint64_t)timestamp argument: (NSString *)argument;
- (void) save: (NSURL *)file;
- (void) close;
@end
#define VL_LOG_EVENT(_ev, _ts, _arg) [[EventLogger sharedLogger] log: (_ev) from: NSStringFromClass([self class]) timestamp: (_ts) argument: (_arg)]
#else
#define VL_LOG_EVENT(_ev, _ts, _arg)
#endif