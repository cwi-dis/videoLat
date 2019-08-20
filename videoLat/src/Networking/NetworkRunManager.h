///
///  @file NetworkRunManager.h
///  @brief Defines NetworkRunManager object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "BaseRunManager.h"
#import "NetworkSelectionView.h"
#import "NetworkOutputView.h"
#import "NetworkInput.h"

///
/// Subclass of BaseRunManager that handles transmitting and receiving measurement
/// data over the network.
///
/// This class is never used as-is, it is always used as only an input component or only an output component.
///
@interface NetworkRunManager : BaseRunManager {
	uint64_t tsLastReported;			//!< Local timestamp of last qr-code detection reported to the master

    uint64_t lastDetectionReceivedTime; //!< Internal: Last time we received a QR-code detection

    NSString *prevInputCode;			//!< Internal: for checking monotonous increase
    int prevInputCodeDetectionCount;    //!< Internal: Number of times we re-detected a code.

    uint64_t averageFinderDuration;		//!< Running average of how much the patternfinder takes
#ifdef WITH_SET_MIN_CAPTURE_DURATION
	BOOL captureDurationWasSet;
#endif
    BOOL sendMeasurementResults;        //!< Internal: send measurement results to remote
}

@property(weak) IBOutlet id <ClockProtocol> clock;              //!< Assigned in NIB: clock source
@property(weak) IBOutlet NetworkSelectionView *selectionView;   //!< UI element: all available cameras
@property(weak) IBOutlet id <InputVideoFindProtocol> finder;    //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet NetworkInput *networkDevice;
//@property(weak) IBOutlet NetworkOutputView *outputView;         //!< Assigned in NIB: visual feedback view of output for the user

+ (void)initialize;	//!< Class initializer.

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop pre-measuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button


@end
