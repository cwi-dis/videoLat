//
//  HardwareOutputView.h
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <AVFoundation/AVFoundation.h>
#import "protocols.h"
#import "AudioProcess.h"

@class AudioRunManager;

///
/// Subclass of NSView that allows the user to select the output device to use, gives
/// some visual feedback on the audio level transmitted and allows the user to select the
/// audio sample to use and the output device.
///

@interface AudioOutputView
#ifdef WITH_UIKIT
: UIView <OutputViewProtocol, AVAudioPlayerDelegate>
#else
: NSView <OutputViewProtocol, AVAudioPlayerDelegate>
#endif
{
    NSArray *samples;       //!< list of available sample filenames
    AVAudioPlayer *player;  //!< AVFoundatio audio player object
    NSArray *signature;     //!< AudioProcess signature of current sample
}

@property BOOL mirrored;    //!< Ignored, this is an audio device
@property(readonly) NSString *deviceID;	//!< Unique string that identifies the output device
@property(readonly) NSString *deviceName;	//!< Human-readable string that identifies the output device
@property(weak) IBOutlet AudioRunManager *manager; //!< Set by NIB: our run manager
@property(weak) IBOutlet AudioProcess *processor;   //!< Set by NIB: our audio processor
#ifdef WITH_UIKIT
@property(weak) IBOutlet UISlider *bVolume;         //!< UI element: slider to adjust output volume
@property(weak) IBOutlet UIProgressView *bOutputValue;    //!< UI element: output VU meter
#else
@property(weak) IBOutlet NSPopUpButton *bSample;    //!< UI element: popup to select audio sample to play
@property(weak) IBOutlet NSSlider *bVolume;         //!< UI element: slider to adjust output volume
@property(weak) IBOutlet NSLevelIndicator *bOutputValue;    //!< UI element: output VU meter
#endif

+ (NSString *)defaultOutputDevice;
- (void)stop;                           //!< Called by manager when user stops the measurement run
- (void) showNewData;                   //!< Called by manager when a new sample should be played
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;    //!< AVAudioPlayer callback routine
- (BOOL)switchToSample: (NSString *)sampleName;

#ifdef WITH_APPKIT
- (IBAction)sampleChanged: (id) sender; //!< Called from UI when a new item has been selected in bSample
#endif

@end
