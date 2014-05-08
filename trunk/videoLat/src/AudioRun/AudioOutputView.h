//
//  HardwareOutputView.h
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "protocols.h"
#import "AudioProcess.h"

@interface AudioOutputView : NSView <OutputViewProtocol, AVAudioPlayerDelegate> {
    NSArray *samples;
    AVAudioPlayer *player;
    NSArray *signature;
}

@property BOOL mirrored; // Ignored
@property(readonly) NSString *deviceID;
@property(readonly) NSString *deviceName;
//@property(weak) IBOutlet NSObject <HardwareLightProtocol> *device;
@property(weak) IBOutlet id <RunOutputManagerProtocol> manager;
@property(weak) IBOutlet AudioProcess *processor;
@property(weak) IBOutlet NSPopUpButton *bSample;
@property(weak) IBOutlet NSSlider *bVolume;
@property(weak) IBOutlet NSLevelIndicator *bOutputValue;

- (void)stop;
- (IBAction)sampleChanged: (id) sender;
- (void) showNewData;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
@end
