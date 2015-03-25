//
//  InputSelectionView.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 25/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "InputSelectionView.h"

@implementation InputSelectionView
@synthesize selectionDelegate;

- (void)setBases: (NSArray *)baseNames
{
    assert(self.bBase);
#ifdef WITH_UIKIT
    assert(0);
#else
    [self.bBase removeAllItems];
    [self.bBase addItemsWithTitles: baseNames];
    [self.selectionDelegate selectionChanged:self];
#endif
}

- (void)disableBases
{
    if (self.bBase) {
#ifdef WITH_UIKIT
        [self.bBase removeFromSuperview];
        if (self.bBaseLabel) [self.bBaseLabel removeFromSuperview];
        self.bBase = nil;
        self.bBaseLabel = nil;
#else
        [self.bBase setEnabled: NO];
        [self.bBase selectItem: nil];
#endif
    }
}

- (NSString *)baseName
{
    if (self.bBase == nil) return nil;

    assert(0);
    return nil;
}

- (NSString *)deviceName
{
    NSString *deviceName = self.bInputDeviceName.text;
    return deviceName;
}

@end
