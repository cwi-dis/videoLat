//
//  DownloadSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 08/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DownloadSelectionView : NSViewController {
    NSArray *calibrations;
}

@property(weak) IBOutlet NSPopUpButton *bCalibrations;
@property NSArray* availableCalibrations;

- (IBAction) cancelDownload: (id)sender;
- (IBAction) doDownload: (id)sender;
- (void)_updateCalibrations;
- (void)_downloadCalibration: (NSDictionary *)calibration;

@end
