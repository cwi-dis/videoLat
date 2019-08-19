//
//  HardwareOutputView.m
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareOutputView.h"

@implementation HardwareOutputView
- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.manager);
    assert(self.hardwareInputHandler);
}

- (NSString *)deviceID
{
	return self.hardwareInputHandler.deviceID;
}

- (NSString *)deviceName
{
	return self.hardwareInputHandler.deviceID;
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
	assert(self.hardwareInputHandler);
	// Video output devices cannot switch (they're tied to the display their window is on)
	NSString *currentName = self.deviceName;
	return [name isEqualToString:currentName];
}

- (BOOL)available {
	return self.hardwareInputHandler.available;
}

- (void)stop {
    [self.hardwareInputHandler stop];
}

- (void)showNewData
{
    NSString *code = [self.manager getNewOutputCode];
    [self.hardwareInputHandler setOutputCode:code report:YES];
    [self performSelectorOnMainThread:@selector(showCode:) withObject:code waitUntilDone:NO];
}

- (void)showCode: (NSString *)code
{
    NSCellStateValue oVal = NSMixedState;
    if ([code isEqualToString:@"white"]) {
        oVal = NSOnState;
    } else if ([code isEqualToString: @"black"]) {
        oVal = NSOffState;
    }
    [self.bOutputValue setState: oVal];
}
@end
