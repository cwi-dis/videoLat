//
//  MeasurementVideoSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioInput.h"

@interface AudioSelectionView : NSView
@property(weak) IBOutlet NSPopUpButton *bOutputDevices;
@property(weak) IBOutlet NSPopUpButton *bInputDevices;
@property(weak) IBOutlet NSPopUpButton *bBase;
@property(weak) IBOutlet NSButton *bPreRun;
@property(weak) IBOutlet NSButton *bRun;
@property(weak) IBOutlet AudioInput *inputHandler;

- (void)_updateDeviceNames: (NSNotification*) notification;
- (IBAction)inputChanged: (id) sender;
- (IBAction)outputChanged: (id) sender;
- (void)_reselectInput: (NSString *)name;
- (void)_reselectOutput: (NSString *)name;

@end
