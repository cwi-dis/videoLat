///
///  @file VideoRunManager.h
///  @brief Implements QR-code video measurements.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "VideoSelectionView.h"
#import "protocols.h"
#import "BaseRunManager.h"

///
/// Subclass of BaseRunManager that handles video measurements based on QR codes.
///
@interface VideoRunManager : BaseRunManager {
    CIImage *outputCodeImage;       //!< Internal: Current code as a CIImage

    NSString *prevInputCode;        //!< Internal: for checking monotonous increase
    int prevInputCodeDetectionCount;    //!<Internal: Number of times we re-detected a code.

	uint64_t tsOutEarliest;			//!< Earliest possible time our output code may have been transmitted
	uint64_t tsOutLatest;			//!< Latest possible time our output code may have been transmitted
	uint64_t tsFrameEarliest;		//!< Earliest possible time the most recent frame may have been captured
	uint64_t tsFrameLatest;			//!< Latest possible time the most recent frame may have been captured
	
    uint64_t averageFinderDuration; //!< Running average of how much the patternfinder takes
}

@property bool mirrored;    //!< True if we need to mirror output. Initialized during prerun.
@property(weak) IBOutlet VideoSelectionView *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;                  //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet NSObject<InputVideoFindProtocol> *finder;        //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet NSObject<OutputVideoGenProtocol> *genner;        //!< Assigned in NIB: generates QR codes for output

+ (void)initialize;
- (VideoRunManager *)init;  //!< Initializer
-(void)stop;

- (void)triggerNewOutputValue;
- (void) _prerunRecordNoReception;                  //!< Internal: no QR code was received in time during prerun
- (void) _prerunRecordReception: (NSString *)code;  //!< Internal: QR code was received in time during prerun

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

// MeasurementInputManagerProtocol
- (void)setFinderRect: (NSorUIRect)theRect;
- (void)newInputStart:(uint64_t)timestamp;
- (void)newInputStart;
- (void)newInputDone: (CVImageBufferRef)image;
@end
