//
//  MeasurementVideoSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "HardwareSelectionView.h"
#import "AppDelegate.h"

@implementation HardwareSelectionView
@synthesize inputSelectionDelegate;
#ifdef WITH_APPKIT
@synthesize bInputDevices;
@synthesize bBase;
#endif

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.bInputDevices);
    assert(self.inputSelectionDelegate);
    NSArray *names = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).hardwareNames;
    
    if ([names count]) {
        [self.bInputDevices removeAllItems];
        [self.bInputDevices setAutoenablesItems: NO];
        [self.bInputDevices addItemWithTitle:@"Select Hardware Device"];
        [[self.bInputDevices itemAtIndex:0] setEnabled: NO];
        [self.bInputDevices addItemsWithTitles: names];
        [self.bInputDevices selectItemAtIndex:0];
    }
}

#ifdef WITH_APPKIT
- (IBAction)inputDeviceSelectionChanged: (id) sender
{
	NSMenuItem *item = [sender selectedItem];
	NSString *device = [item title];
	NSLog(@"Switch to %@\n", device);
	assert(self.inputSelectionDelegate);
	[self.inputSelectionDelegate inputSelectionChanged: self];
}
#endif

#ifdef WITH_UIKIT
- (void)setBases: (NSArray *)baseNames
{
	assert(self.bBase);
    [self.bBase removeAllItems];
    [self.bBase addItemsWithTitles: baseNames];
	[self.inputSelectionDelegate inputSelectionChanged:self];
}

- (void)disableBases
{
	if (self.bBase) {
		[self.bBase setEnabled: NO];
		[self.bBase selectItem: nil];
	}
}
#endif

- (NSString *)baseName
{
	if (self.bBase == nil) return nil;
	NSMenuItem *item = [self.bBase selectedItem];
	if (item == nil) return nil;
    if (!item.enabled) return nil;
	return [item title];
}

- (NSString *)deviceName
{
	assert(self.bInputDevices);
	NSMenuItem *item = [self.bInputDevices selectedItem];
	if (item == nil) return nil;
    if (!item.enabled) return nil;
	return [item title];
}

@end
