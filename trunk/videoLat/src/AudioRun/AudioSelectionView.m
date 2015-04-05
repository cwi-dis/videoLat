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
    [super awakeFromNib];
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
    // Get all input devices
	assert(self.inputHandler);
    NSArray *newList = [self.inputHandler deviceNames];
	assert(newList);
#ifdef WITH_UIKIT
	NSString *newInput;
	if([newList count]) {
		newInput = [newList objectAtIndex:0];
	} else {
		newInput = nil;
	}
	
	self.bInputDeviceName.text = newInput;
#else
	NSMenuItem *oldItem = [self.bDevices selectedItem];
    if (oldItem) {
        oldInput = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldInput = [[NSUserDefaults standardUserDefaults] stringForKey:@"AudioInput"];
    }
    [self.bDevices removeAllItems];
    [self.bDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectInput:oldInput];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bDevices selectedItem];
    NSString *newInput = [newItem title];
#endif
    if (![newInput isEqualToString:oldInput] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newInput];
    // Repeat for output devices...
}

#ifdef WITH_APPKIT
- (IBAction)deviceChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioInput to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.selectionDelegate);
	[self.selectionDelegate selectionChanged: self];
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
#if 0
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioOutput to %@\n", cam);
//	[self.outputHandler switchToDeviceWithName: cam];
#endif
}

- (NSString *)baseName
{
    if (self.bBase == nil) return nil;
    NSMenuItem *item = [self.bBase selectedItem];
    if (item == nil) return nil;
    return [item title];
}

- (NSString *)deviceName
{
    assert(self.bDevices);
    NSMenuItem *item = [self.bDevices selectedItem];
    if (item == nil) return nil;
    return [item title];
}
#endif


@end
