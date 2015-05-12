//
//  MachineDescription.m
//  videoLat
//
//  Created by Jack Jansen on 2/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "MachineDescription.h"
#import <sys/sysctl.h>
#if !TARGET_OS_IPHONE
#import <SystemConfiguration/SystemConfiguration.h>
#endif

@implementation MachineDescription

+ (MachineDescription *)thisMachine
{
	static MachineDescription *_singleton = nil;
	if (_singleton == nil)
		_singleton = [[MachineDescription alloc] init];
	return _singleton;
}

- (NSString *)machineID
{
	return @"00:00:00:00:00:00"; // XXXX
}

- (NSString *)machineName
{
#if TARGET_OS_IPHONE
	return [[UIDevice currentDevice] name];
#else
    return (__bridge_transfer NSString *)SCDynamicStoreCopyComputerName(nil, nil);
#endif
}

- (NSString *)machineTypeID
{
	char hwName_c[100] = "unknown";
	size_t len = sizeof(hwName_c);
	sysctlbyname("hw.model", hwName_c, &len, NULL, 0);
	NSString *hwName = [NSString stringWithUTF8String:hwName_c];
	return hwName;
}

- (NSString *)os
{
#if TARGET_OS_IPHONE
	NSString *osName = @"iOS";
#else
	NSString *osName = @"OSX";
#endif
	NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
	osName = [NSString stringWithFormat:@"%@-%d.%d.%d", osName, (int)osVersion.majorVersion, (int)osVersion.minorVersion, (int)osVersion.patchVersion];
	return osName;
}
@end
