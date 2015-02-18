//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioSelectionView.h"

@implementation AudioSelectionView

- (void)awakeFromNib
{
    [self _updateDeviceNames: nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateDeviceNames:)
     name:AVCaptureDeviceWasConnectedNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateDeviceNames:)
     name:AVCaptureDeviceWasDisconnectedNotification
     object:nil];
}


- (void)dealloc
{
}


- (void)_updateDeviceNames: (NSNotification*) notification
{
    if (VL_DEBUG) NSLog(@"Audio devices changed\n");
    // Remember the old selection (if any)
    NSString *oldInput = nil;
	NSMenuItem *oldItem = [self.bDevices selectedItem];
    if (oldItem) {
        oldInput = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldInput = [[NSUserDefaults standardUserDefaults] stringForKey:@"AudioInput"];
    }
    // Add all input devices
    NSArray *newList = [self.inputHandler deviceNames];
    [self.bDevices removeAllItems];
    [self.bDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectInput:oldInput];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bDevices selectedItem];
    NSString *newInput = [newItem title];
    if (![newInput isEqualToString:oldInput] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newInput];
    // Repeat for output devices...
}

- (IBAction)deviceChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioInput to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.manager);
	[self.manager deviceChanged: self];
}

- (void)_reselectInput: (NSString *)name
{
    if (name)
        [self.bDevices selectItemWithTitle:name];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bDevices selectedItem];
    if (newItem == nil)
        [self.bDevices selectItemAtIndex: 0];
}

- (IBAction)outputChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioOutput to %@\n", cam);
//	[self.outputHandler switchToDeviceWithName: cam];
}

@end
