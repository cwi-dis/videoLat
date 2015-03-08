//
//  DownloadSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 08/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "DownloadSelectionView.h"
#import "appDelegate.h"

@implementation DownloadSelectionView

@synthesize bCalibrations;

- (void) awakeFromNib
{
    [bCalibrations removeAllItems];
}

- (NSArray *)availableCalibrations { return calibrations; }

- (void)setAvailableCalibrations: (NSArray *)_calibrations
{
    calibrations = _calibrations;
    [self _updateCalibrations];
}

- (void)_updateCalibrations
{
    [bCalibrations removeAllItems];
    NSDictionary *cal;
    appDelegate *ad = (appDelegate *)[[NSApplication sharedApplication] delegate];
    for (cal in calibrations) {
        if ([ad haveCalibration: [cal objectForKey: @"uuid"]])
            continue;
        NSString *calName = [NSString stringWithFormat:@"%@-%@-%@-%@",
                             [cal objectForKey:@"measurementTypeID"],
                             [cal objectForKey:@"machineTypeID"],
                             [cal objectForKey:@"deviceID"],
                             [cal objectForKey:@"uuid"]
                             ];
        [bCalibrations addItemWithTitle:calName];
    }
}

- (IBAction) cancelDownload: (id)sender
{
    [[[self view] window] close];
}

- (IBAction) doDownload: (id)sender
{
    NSLog(@"Should download");
    NSInteger index = [bCalibrations indexOfSelectedItem];
    if (index >= 0) {
        [self _downloadCalibration: [calibrations objectAtIndex:index]];
    }
}

- (void)downloadCalibration: (NSDictionary *)calibration
{
}

@end
