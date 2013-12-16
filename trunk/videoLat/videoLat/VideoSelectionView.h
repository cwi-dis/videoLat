//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoInput.h"

@interface VideoSelectionView : NSView
@property(weak) IBOutlet NSPopUpButton *bCameras;
@property(weak) IBOutlet NSPopUpButton *bBase;
@property(weak) IBOutlet NSButton *bPreRun;
@property(weak) IBOutlet NSButton *bRun;
@property(weak) IBOutlet VideoInput *inputHandler;

- (IBAction)cameraChanged: (id) sender;
- (void)_updateCameraNames: (NSNotification*) notification;
- (void)_reselectCamera: (NSString *)name;

@end
