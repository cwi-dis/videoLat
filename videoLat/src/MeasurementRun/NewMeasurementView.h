//
//  NewMeasurement.h
//  videoLat
//
//  Created by Jack Jansen on 24/02/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RunManagerView.h"
#import "DownloadCalibrationViewController.h"

@interface NewMeasurementViewController : NSViewController<DownloadDelegate, NSWindowDelegate> {
    NSArray *runManagerNibObjects;	//!< internal: storage for toplevel object references from loaded nibfiles
}

@property(weak) IBOutlet NSPopUpButton *bType;              //!< Set by our NIB: reference to the measurement type button
@property(weak) IBOutlet NSWindow *measurementWindow;       //!< Set by measurement NIB (on file owner): its window
@property(weak) IBOutlet RunManagerView *runManagerView;    //!< Set by measurement NIB (on file owner): its view
@property(weak) IBOutlet DownloadCalibrationViewController *downloadCalibrationViewController;
@property(weak) IBOutlet NSTabView *tabView;

- (IBAction)doMeasurement:(id)sender;
- (void)didDownload: (MeasurementDataStore *)dataStore;
@end
