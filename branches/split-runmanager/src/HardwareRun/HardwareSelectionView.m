//
//  MeasurementVideoSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareSelectionView.h"
#import "appDelegate.h"

@implementation HardwareSelectionView

- (void)awakeFromNib
{
    NSArray *names = ((appDelegate *)[[NSApplication sharedApplication] delegate]).hardwareNames;
    
    if ([names count]) {
        [self.bDevices removeAllItems];
        [self.bDevices setAutoenablesItems: NO];
        [self.bDevices addItemWithTitle:@"Select Hardware Device"];
        [[self.bDevices itemAtIndex:0] setEnabled: NO];
        [self.bDevices addItemsWithTitles: names];
        [self.bDevices selectItemAtIndex:0];
    }
}


- (IBAction)deviceChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *device = [item title];
	NSLog(@"Switch to %@\n", device);
    assert(0);
//	[self.manager switchToDeviceWithName: cam];
}

@end
