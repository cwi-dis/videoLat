//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iSight.h"

@interface MeasurementVideoSelectionView : NSView
@property(retain) IBOutlet NSPopUpButton *bCameras;
@property(retain) IBOutlet NSPopUpButton *bBase;
@property(retain) IBOutlet NSButton *bRun;
@property(retain) IBOutlet iSight *inputHandler;

- (IBAction)cameraChanged: (id) sender;
- (void)_updateCameraNames: (NSNotification*) notification;
- (void)_reselectCamera: (NSString *)name;

@end
