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

@interface AudioRunManager : BaseRunManager {
    uint64_t outputStartTime;       // When the last output was started
	BOOL outputActive;				// True while we are outputting (and can't start again
	BOOL foundCurrentSample;		// True if we have found a match
	BOOL triggerOutputWhenDone;		// True if we can start a new output when the current one is done

    uint64_t maxDelay;				// How long to wait for code finding
    int prerunMoreNeeded;           // How many more prerun correct catches we need
    
}
//@property(weak) IBOutlet NSPopUpButton *bBase;
@property(weak) IBOutlet AudioOutputView *outputView;
@property(weak) IBOutlet AudioSelectionView *selectionView;
@property(weak) IBOutlet id <InputCaptureProtocol> capturer;
@property(weak) IBOutlet id <ClockProtocol> clock;
@property(weak) IBOutlet NSButton *bDetection;
@property(weak) IBOutlet AudioProcess *processor;

+ (void)initialize;
- (AudioRunManager *)init;
- (void)stop;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;

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
