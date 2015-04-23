//
//  EventLogger.h
//  videoLat
//
//  Created by Jack Jansen on 10/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"


#ifdef WITH_LOGGING

///
/// Object to created timed log file of low level events.
///
@interface EventLogger : NSObject
{
	FILE *fp;
}

/// Return singleton event logger.
/// @return The singleton event logger.
+ (EventLogger *)sharedLogger;

/// Log an event.
/// @param event Textual representation of what happened.
/// @param module Name of the module that generated to log message.
/// @param timestamp An optional timestamp (in microseconds) coresponding to this event.
/// @param argument An optional string that gives more information about the event.
- (void) log: (NSString *)event from: (NSString *)module timestamp: (uint64_t)timestamp argument: (NSString *)argument;

/// Start logging.
/// @param file The URL for the file to which the log should be saved.
- (void) save: (NSURL *)file;

/// Stop logging.
- (void) close;
@end
/// Convenience macro to log an event if the logger has been configured at compile time.
/// @param _ev The NSString event
/// @param _ts The uint64_t microsencd timestamp
/// @param _arg The NSString optional argument
#define VL_LOG_EVENT(_ev, _ts, _arg) [[EventLogger sharedLogger] log: (_ev) from: NSStringFromClass([self class]) timestamp: (_ts) argument: (_arg)]
#else
#define VL_LOG_EVENT(_ev, _ts, _arg)
#endif