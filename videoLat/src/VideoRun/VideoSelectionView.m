//
//  MeasurementVideoSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "VideoSelectionView.h"

@implementation VideoSelectionView
@synthesize inputSelectionDelegate;
#ifdef WITH_APPKIT
@synthesize bInputDevices;
@synthesize bBase;
@synthesize bPreRun;
#endif

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.inputHandler);
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
	self.bInputDeviceName.text = newCam;
#else
    if (VL_DEBUG) NSLog(@"Cameras changed\n");
    // Remember the old selection (if any)
	NSMenuItem *oldItem = [self.bInputDevices selectedItem];
    if (oldItem) {
        oldCam = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldCam = [[NSUserDefaults standardUserDefaults] stringForKey:@"Camera"];
    }
    // Add all cameras
    [self.bInputDevices removeAllItems];
    [self.bInputDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectCamera:oldCam];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bInputDevices selectedItem];
    newCam = [newItem title];
#endif
    if (![newCam isEqualToString:oldCam] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newCam];
}

#ifdef WITH_UIKIT
- (IBAction)selectNextCamera: (id)sender
{
    NSArray *newList = [self.inputHandler deviceNames];
	NSUInteger index = [newList indexOfObject: self.bInputDeviceName.text];
	if (index == NSNotFound)
		index = -1;
	index++;
	if (index >= [newList count]) index = 0;
	NSString *newCam = [newList objectAtIndex:index];
	self.bInputDeviceName.text = newCam;
	[self.inputHandler switchToDeviceWithName:newCam];
}
#endif

#ifdef WITH_APPKIT
- (void)_reselectCamera: (NSString *)oldCam
{
    if (oldCam)
        [self.bInputDevices selectItemWithTitle:oldCam];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bInputDevices selectedItem];
    if (newItem == nil)
        [self.bInputDevices selectItemAtIndex: 0];
}

- (IBAction)inputDeviceChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	NSLog(@"Switch to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.inputSelectionDelegate);
	[self.inputSelectionDelegate inputSelectionChanged: self];
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
    if(!self.bInputDevices) return nil;
    NSMenuItem *item = [self.bInputDevices selectedItem];
    if (item == nil) return nil;
    return [item title];
}
#endif

@end
