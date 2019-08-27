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
    assert(self.hardwareIODevice);
}

- (NSString *)deviceID
{
	return self.hardwareIODevice.deviceID;
}

- (NSString *)deviceName
{
	return self.hardwareIODevice.deviceID;
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
	assert(self.hardwareIODevice);
	// Video output devices cannot switch (they're tied to the display their window is on)
    return [self.hardwareIODevice switchToDeviceWithName: name];
}

- (BOOL)available {
    assert(self.hardwareIODevice);
	return self.hardwareIODevice.available;
}

- (void)stop {
    [self.hardwareIODevice stop];
}

- (void)showNewData
{
    [self.hardwareIODevice showNewData];
#if 0
    [self.showCode: xxxxx];
#endif
}

#if 0
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
#endif
@end
