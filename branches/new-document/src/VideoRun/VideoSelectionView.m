//
//  MeasurementVideoSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoSelectionView.h"

@implementation VideoSelectionView
- (void)awakeFromNib
{
    [self _updateCameraNames: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateCameraNames:)
     name:AVCaptureDeviceWasConnectedNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateCameraNames:)
     name:AVCaptureDeviceWasDisconnectedNotification
     object:nil];
}

- (void)_updateCameraNames: (NSNotification*) notification
{
    if (VL_DEBUG) NSLog(@"Cameras changed\n");
    // Remember the old selection (if any)
    NSString *oldCam = nil;
	NSMenuItem *oldItem = [self.bDevices selectedItem];
    if (oldItem) {
        oldCam = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldCam = [[NSUserDefaults standardUserDefaults] stringForKey:@"Camera"];
    }
    // Add all cameras
    NSArray *newList = [self.inputHandler deviceNames];
    [self.bDevices removeAllItems];
    [self.bDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectCamera:oldCam];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bDevices selectedItem];
    NSString *newCam = [newItem title];
    if (![newCam isEqualToString:oldCam] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newCam];
}

- (void)_reselectCamera: (NSString *)oldCam
{
    if (oldCam)
        [self.bDevices selectItemWithTitle:oldCam];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bDevices selectedItem];
    if (newItem == nil)
        [self.bDevices selectItemAtIndex: 0];
}

- (IBAction)deviceChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	NSLog(@"Switch to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.manager);
	[self.manager deviceChanged: self];
}

@end