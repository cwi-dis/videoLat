//
//  MachineDescription.m
//  videoLat
//
//  Created by Jack Jansen on 2/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "MachineDescription.h"
#import <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>

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
    return (__bridge_transfer NSString *)SCDynamicStoreCopyComputerName(nil, nil);
}

- (NSString *)machineTypeID
{
	char hwName_c[100] = "unknown";
	size_t len = sizeof(hwName_c);
	sysctlbyname("hw.model", hwName_c, &len, NULL, 0);
	NSString *hwName = [NSString stringWithUTF8String:hwName_c];
	return hwName;
}

@end
