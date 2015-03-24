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
    NSArray *newList = [self.inputHandler deviceNames];
    NSString *oldCam = nil;
	NSString *newCam = nil;
#ifdef WITH_UIKIT
	if (newList && [newList count]) {
		newCam = [newList objectAtIndex:0];
	}
	self.bDeviceName.text = newCam;
#else
    if (VL_DEBUG) NSLog(@"Cameras changed\n");
    // Remember the old selection (if any)
	NSMenuItem *oldItem = [self.bDevices selectedItem];
    if (oldItem) {
        oldCam = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldCam = [[NSUserDefaults standardUserDefaults] stringForKey:@"Camera"];
    }
    // Add all cameras
    [self.bDevices removeAllItems];
    [self.bDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectCamera:oldCam];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bDevices selectedItem];
    newCam = [newItem title];
#endif
    if (![newCam isEqualToString:oldCam] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newCam];
}

#ifdef WITH_UIKIT
- (IBAction)selectNextCamera: (id)sender
{
    NSArray *newList = [self.inputHandler deviceNames];
	NSUInteger index = [newList indexOfObject: self.bDeviceName.text];
	if (index == NSNotFound)
		index = -1;
	index++;
	if (index >= [newList count]) index = 0;
	NSString *newCam = [newList objectAtIndex:index];
	self.bDeviceName.text = newCam;
	[self.inputHandler switchToDeviceWithName:newCam];
}
#endif

- (void)_reselectCamera: (NSString *)oldCam
{
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
    if (oldCam)
        [self.bDevices selectItemWithTitle:oldCam];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bDevices selectedItem];
    if (newItem == nil)
        [self.bDevices selectItemAtIndex: 0];
#endif
}

- (IBAction)deviceChanged: (id) sender
{
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	NSLog(@"Switch to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.selectionDelegate);
	[self.selectionDelegate selectionChanged: self];
#endif
}

- (void)setBases: (NSArray *)baseNames
{
	assert(self.bBase);
#ifdef WITH_UIKIT
	assert(0);
#else
    [self.bBase removeAllItems];
    [self.bBase addItemsWithTitles: baseNames];
#endif
	[self.selectionDelegate selectionChanged:self];
}

- (void)disableBases
{
	if (self.bBase) {
#ifdef WITH_UIKIT
		assert(0);
#else
		[self.bBase setEnabled: NO];
		[self.bBase selectItem: nil];
#endif
	}
}

- (NSString *)baseName
{
	if (self.bBase == nil) return nil;
#ifdef WITH_UIKIT
	assert(0);
	return nil;
#else
	NSMenuItem *item = [self.bBase selectedItem];
	if (item == nil) return nil;
	return [item title];
#endif
}

- (NSString *)deviceName
{
#ifdef WITH_UIKIT
	assert(0);
	return nil;
#else
	assert(self.bDevices);
	NSMenuItem *item = [self.bDevices selectedItem];
	if (item == nil) return nil;
	return [item title];
#endif
}

@end
