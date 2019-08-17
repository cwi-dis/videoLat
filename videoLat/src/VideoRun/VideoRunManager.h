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

    uint64_t averageFinderDuration; //!< Running average of how much the patternfinder takes
}

@property(weak) IBOutlet VideoSelectionView *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet NSObject<ClockProtocol> *clock;                  //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet NSObject<InputVideoFindProtocol> *finder;        //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet NSObject<OutputVideoGenProtocol> *genner;        //!< Assigned in NIB: generates QR codes for output

- (VideoRunManager *)init;  //!< Initializer

- (void) prepareReceivedNoValidCode;                  //!< Internal: no QR code was received in time during prerun
- (void) prepareReceivedValidCode: (NSString *)code;  //!< Internal: QR code was received in time during prerun
- (void) _newOutputCode;							//!< Internal: set outputCode to a new value (depending on running/prerunning/idle)
@end
