//
//  HardwareOutputView.m
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
