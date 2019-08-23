//
//  NetworkSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkSelectionView.h"
@implementation NetworkSelectionView
#ifdef WITH_APPKIT
@synthesize bBase;
@synthesize bInputDevices;
#endif
@synthesize inputSelectionDelegate;

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportClient ip=%@ port=%d isUs=%d", ip, port, us);
}

- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportServer ip=%@ port=%d isUs=%d", ip, port, us);
}

- (NSString *)deviceName {
    NSLog(@"networkSelectionView deviceName called");
    return @"NetworkInput";
}

#ifdef WITH_APPKIT
- (void)inputDeviceSelectionChanged:(id)sender {
    NSLog(@"networkInputSelectionView inputDeviceSelectionChanged called");
    assert(0);
}

- (BOOL)setBases: (NSArray *)baseNames
{
    assert(self.bBase);
    NSArray *oldNames = self.bBase.itemTitles;
    if ([baseNames isEqualToArray:oldNames]) {
        return YES;
    }
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

#endif
@end
