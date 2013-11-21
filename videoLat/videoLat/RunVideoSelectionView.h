//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputCamera.h"

@interface RunVideoSelectionView : NSView
@property(retain) IBOutlet NSPopUpButton *bCameras;
@property(retain) IBOutlet NSPopUpButton *bBase;
@property(retain) IBOutlet NSButton *bRun;
@property(retain) IBOutlet InputCamera *inputHandler;

- (IBAction)cameraChanged: (id) sender;
- (void)_updateCameraNames: (NSNotification*) notification;
- (void)_reselectCamera: (NSString *)name;

@end
