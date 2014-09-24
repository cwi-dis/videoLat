//
//  OutputManager.h
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "protocols.h"
#import "BaseRunManager.h"
#import "AudioSelectionView.h"
#import "AudioOutputView.h"
#import "AudioProcess.h"

///
/// Subclass of BaseRunManager that handles audio delay measurements.
/// Transmits a sample through the line-out (or speaker) and waits for that same
/// sample to be received on the line-in (or microphone).
/// Current implementation does not behave very well in case of echo supression
/// or echo cancellation.
///
@interface AudioRunManager : BaseRunManager {
    uint64_t outputStartTime;       //!< When the last output was started
	BOOL outputActive;				//!< True while we are outputting (and can't start again
	BOOL foundCurrentSample;		//!< True if we have found a match
	BOOL triggerOutputWhenDone;		//!< True if we can start a new output when the current one is done

    uint64_t maxDelay;				//!< How long to wait for code finding
    int prerunMoreNeeded;           //!< How many more prerun correct catches we need
    
}

@property(weak) IBOutlet AudioOutputView *outputView;           //!< Assigned in NIB: visual feedback view of output for the user
@property(weak) IBOutlet AudioSelectionView *selectionView;     //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet id <InputCaptureProtocol> capturer;    //!< Assigned in NIB: audio input capturer
@property(weak) IBOutlet id <ClockProtocol> clock;              //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet NSButton *bDetection;                  //!< Assigned in NIb: UI element that signals detection to the user
@property(weak) IBOutlet AudioProcess *processor;               //!< Assigned in NIB: audio sample comparator

+ (void)initialize;
- (AudioRunManager *)init;  //!< Initializer
- (void)stop;

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button

- (void)triggerNewOutputValue;
//- (void) _prerunRecordNoReception;
//- (void) _prerunRecordReception: (NSString *)code;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

#if 0
// MeasurementInputManagerProtocol
- (void)restart;
- (void)setFinderRect: (NSRect)theRect;
- (void)newInputStart:(uint64_t)timestamp;
- (void)newInputStart;
- (void)newInputDone;
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
#endif
@end
