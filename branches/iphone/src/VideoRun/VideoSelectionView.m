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
#ifdef WITH_UIKIT_TEMP
	assert(0);
#else
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
#endif
}

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
