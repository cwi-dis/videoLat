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
	return self.hardwareInputHandler.deviceID;
}

- (NSString *)deviceName
{
	return self.hardwareInputHandler.deviceID;
}


- (BOOL)available {
	return self.hardwareInputHandler.available;
}

- (void) showNewData
{
}

@end
