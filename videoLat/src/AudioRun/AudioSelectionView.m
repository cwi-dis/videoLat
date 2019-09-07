//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioSelectionView.h"
#import "AudioOutputView.h"

@implementation AudioSelectionView
@synthesize inputSelectionDelegate;
#ifdef WITH_APPKIT
@synthesize bBase;
@synthesize bInputDevices;
#endif

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.inputHandler);
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
#ifdef AVAudioSessionRouteChangeNotification
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(_updateDeviceNames:)
     name:AVAudioSessionRouteChangeNotification
     object:nil];
#endif
}

- (void)dealloc
{
}

- (void)_updateDeviceNames: (NSNotification*) notification
{
    if (1 || VL_DEBUG) NSLog(@"Audio devices changed, userInfo=%@\n", notification.userInfo);
    // Remember the old selection (if any)
    NSString *oldInput = nil;
    // Get all input devices
	assert(self.inputHandler);
    NSArray *newList = [self.inputHandler deviceNames];
	assert(newList);
#ifdef WITH_UIKIT
    oldInput = self.bInputDeviceName.text;
	NSString *newInput;
	if([newList count]) {
		newInput = [newList objectAtIndex:0];
	} else {
		newInput = nil;
	}
	
	self.bInputDeviceName.text = newInput;
    if (1 || VL_DEBUG) NSLog(@"new audio input=%@", newInput);
    self.bOutputDeviceName.text = [AudioOutputView defaultOutputDevice];
#else
	NSMenuItem *oldItem = [self.bInputDevices selectedItem];
    if (oldItem) {
        oldInput = [oldItem title];
    } else {
        // If no camera was selected we take the one from the preferences
        oldInput = [[NSUserDefaults standardUserDefaults] stringForKey:@"AudioInput"];
    }
    [self.bInputDevices removeAllItems];
    [self.bInputDevices addItemsWithTitles: newList];
    // Re-select old selection, if possible
    [self _reselectInput:oldInput];
    // Tell the input handler if the device has changed
    NSMenuItem *newItem = [self.bInputDevices selectedItem];
    NSString *newInput = [newItem title];
#endif
    if (![newInput isEqualToString:oldInput] || notification == nil)
        [self.inputHandler switchToDeviceWithName:newInput];
    // Repeat for output devices...
}

#ifdef WITH_APPKIT
- (IBAction)inputDeviceSelectionChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *cam = [item title];
	if (VL_DEBUG) NSLog(@"Switch audioInput to %@\n", cam);
	[self.inputHandler switchToDeviceWithName: cam];
	assert(self.inputSelectionDelegate);
	[self.inputSelectionDelegate inputSelectionChanged: self];
}

- (void)_reselectInput: (NSString *)name
{
    if (name)
        [self.bInputDevices selectItemWithTitle:name];
    // Select first item, if nothing has been selected
    NSMenuItem *newItem = [self.bInputDevices selectedItem];
    if (newItem == nil)
        [self.bInputDevices selectItemAtIndex: 0];
}

- (IBAction)outputChanged: (id) sender
{
}


- (BOOL)setBases: (NSArray *)baseNames
{
    assert(self.bBase);
    [self.bBase removeAllItems];
    [self.bBase addItemsWithTitles: baseNames];
    BOOL ok = self.bBase.numberOfItems > 0;
    if (ok) {
        [self.bBase selectItemAtIndex:0];
        [self.inputSelectionDelegate inputSelectionChanged:self];
    }
    return ok;
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
    assert(self.bInputDevices);
    NSMenuItem *item = [self.bInputDevices selectedItem];
    if (item == nil) return nil;
    return [item title];
}
#endif

@end
