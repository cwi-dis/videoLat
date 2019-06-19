///
///  @file AudioRunManager.h
///  @brief Implements audio roundtrip measurements.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "protocols.h"
#import "BaseRunManager.h"
#import "AudioOutputView.h"
#import "AudioProcess.h"
#import "AudioSelectionView.h"

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
}

@property(weak) IBOutlet AudioOutputView *outputView;           //!< Assigned in NIB: visual feedback view of output for the user
@property(weak) IBOutlet AudioSelectionView *selectionView;     //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet id <ClockProtocol> clock;              //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet AudioProcess *processor;               //!< Assigned in NIB: audio sample comparator
#ifdef WITH_UIKIT
@property(weak) IBOutlet UISwitch *bDetection;                  //!< Assigned in NIb: UI element that signals detection to the user
#else
@property(weak) IBOutlet NSButton *bDetection;                  //!< Assigned in NIb: UI element that signals detection to the user
#endif
+ (void)initialize;
- (AudioRunManager *)init;  //!< Initializer
- (void)stop;

- (void)triggerNewOutputValue;
//- (void) _prerunRecordNoReception;
//- (void) _prerunRecordReception: (NSString *)code;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputStartAt: (uint64_t) startTime;
- (void)newOutputDone;

@end
