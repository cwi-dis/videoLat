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

- (void)awakeFromNib
{
    [super awakeFromNib];
    assert(self.bDevices);
    assert(self.bPreRun);
    assert(self.selectionDelegate);
    NSArray *names = ((AppDelegate *)[[NSApplication sharedApplication] delegate]).hardwareNames;
    
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
	assert(self.selectionDelegate);
	[self.selectionDelegate selectionChanged: self];
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
    if (!item.enabled) return nil;
	return [item title];
}

- (NSString *)deviceName
{
	assert(self.bDevices);
	NSMenuItem *item = [self.bDevices selectedItem];
	if (item == nil) return nil;
    if (!item.enabled) return nil;
	return [item title];
}

@end
