///
///  @file VideoRunManager.h
///  @brief Implements QR-code video measurements.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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

	uint64_t outputFrameEarliestTimestamp;			//!< Earliest possible time our output code may have been transmitted
	uint64_t outputFrameLatestTimestamp;			//!< Latest possible time our output code may have been transmitted
#ifdef WITH_FRAMETIME_COMPUTE
    uint64_t tsFrameEarliest;		//!< Earliest possible time the most recent frame may have been captured
	uint64_t tsFrameLatest;			//!< Latest possible time the most recent frame may have been captured
#else
    uint64_t inputFrameTimestamp;   //!< Timestamp of current video frame (or 0 if already processed)
#endif
    uint64_t averageFinderDuration; //!< Running average of how much the patternfinder takes
}

@property(weak) IBOutlet VideoSelectionView *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;                  //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet NSObject<InputVideoFindProtocol> *finder;        //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet NSObject<OutputVideoGenProtocol> *genner;        //!< Assigned in NIB: generates QR codes for output

- (VideoRunManager *)init;  //!< Initializer

- (void) _prerunRecordNoReception;                  //!< Internal: no QR code was received in time during prerun
- (void) _prerunRecordReception: (NSString *)code;  //!< Internal: QR code was received in time during prerun
- (void) _newOutputCode;							//!< Internal: set outputCode to a new value (depending on running/prerunning/idle)
@end
