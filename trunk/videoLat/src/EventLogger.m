//
//  EventLogger.m
//  videoLat
//
//  Created by Jack Jansen on 10/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "EventLogger.h"
#import "compat.h"

#ifdef WITH_LOGGING
@interface EventLogger ()
- (EventLogger *)init;
- (uint64_t) now;
@end

@implementation EventLogger

+ (EventLogger *)sharedLogger
{
	static EventLogger *_sharedLogger = nil;
	if (_sharedLogger == nil) {
		_sharedLogger = [[EventLogger alloc] init];
	}
	return _sharedLogger;
}

- (EventLogger *)init
{
	self = [super init];
	fp = nil;
	return self;
}

- (uint64_t)now
{
    return monotonicMicroSecondClock();
}

- (void)log: (NSString *)event from: (NSString *)module timestamp: (uint64_t)timestamp argument: (NSString *)argument
{
	if (fp == nil) return;
	NSString *line = [NSString stringWithFormat:@"%lld,\"%@\",\"%@\",%lld,\"%@\"\n", [self now], module, event, timestamp, argument];
	fputs(line.UTF8String, fp);
}

- (void) save: (NSURL *)file
{
	const char *filename = file.fileSystemRepresentation;
	fp = fopen(filename, "w");
	if (fp == nil) {
		showWarningAlert(@"Cannot create log file for writing");
		return;
	}
	fputs("systemTimeMicro,moduleName,eventName,eventTimeMicro,eventArgument\n", fp);
}

- (void)close
{
	fclose(fp);
	fp = nil;
}

@end
#endif
