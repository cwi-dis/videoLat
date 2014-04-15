//
//  HardwareOutputView.m
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import "HardwareOutputView.h"

@implementation HardwareOutputView
- (NSString *)deviceID
{
	return self.device.deviceID;
}

- (NSString *)deviceName
{
	return self.device.deviceName;
}

- (void) showNewData
{
}

@end
