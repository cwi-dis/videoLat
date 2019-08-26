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

#ifdef WITH_UIKIT
// Gross....
#define stringValue text
#endif


- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bOurPort.stringValue = [NSString stringWithFormat:@"%@:%d", ip, port];
    });
}

- (void) reportStatus: (NSString *_Nonnull)status
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bNetworkStatus.stringValue = status;
    });
}

- (void) reportRTT: (uint64_t)rtt best: (uint64_t)best
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.bRTT.stringValue = [NSString stringWithFormat:@"%lld (best %lld)", rtt/1000, best/1000];
    });
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
