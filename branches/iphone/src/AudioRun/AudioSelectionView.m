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
#ifdef WITH_UIKIT_TEMP
#else
	NSMenuItem *oldItem = [self.bDevices selectedItem];
    if (oldItem) {
        oldInput = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldInput = [[NSUserDefaults standardUserDefaults] stringForKey:@"AudioInput"];
    }
#endif
    // Add all input devices
	assert(self.inputHandler);
    NSArray *newList = [self.inputHandler deviceNames];
#ifdef WITH_UIKIT_TEMP
	assert(newList);
	NSString *newInput;
	if([newList count]) {
		newInput = [newList objectAtIndex:0];
	} else {
		newInput = nil;
	}
#else
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

- (IBAction)deviceChanged: (id) sender
{
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioInput to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.selectionDelegate);
	[self.selectionDelegate selectionChanged: self];
#endif
}

- (void)_reselectInput: (NSString *)name
{
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
    if (name)
        [self.bDevices selectItemWithTitle:name];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bDevices selectedItem];
    if (newItem == nil)
        [self.bDevices selectItemAtIndex: 0];
#endif
}

- (IBAction)outputChanged: (id) sender
{
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioOutput to %@\n", cam);
//	[self.outputHandler switchToDeviceWithName: cam];
#endif
}

- (void)setBases: (NSArray *)baseNames
{
	assert(self.bBase);
    [self.bBase removeAllItems];
    [self.bBase addItemsWithTitles: baseNames];
	[self.selectionDelegate selectionChanged:self];
}

- (void)disableBases
{
	if (self.bBase) {
		[self.bBase setEnabled: NO];
		[self.bBase selectItem: nil];
	}
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

@end
