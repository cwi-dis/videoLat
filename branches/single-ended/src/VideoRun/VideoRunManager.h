//
//  VideoRunManager.h
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "VideoSelectionView.h"
#import "protocols.h"
#import "BaseRunManager.h"

///
/// Subclass of @see BaseRunManager that handles video measurements based on QR codes.
///
@interface VideoRunManager : BaseRunManager {
    uint64_t outputStartTime;       //!< Internal: When the last output was started
    uint64_t prerunOutputStartTime; //!< Internal: Like outputStartTime, but not reset when reported (for prerun duration checking)
    uint64_t prevOutputStartTime;   //!< Internal: For checking that outputStartTime are monotonously increasing
    NSString *prevOutputCode;       //!< Internal: Previous code, for dual detections and checking monotonous increase
    CIImage *outputCodeImage;       //!< Internal: Current code as a CIImage

    uint64_t inputStartTime;        //!< Internal: When last input was read
    uint64_t prevInputStartTime;    //!< Internal: When last input was read
    NSString *prevInputCode;        //!< Internal: for checking monotonous increase
    int prevInputCodeDetectionCount;    //!<Internal: Number of times we re-detected a code.
    
    
    uint64_t prerunDelay;           //!< Internal: How log to wait for prerun code finding
    int prerunMoreNeeded;           //!< Internal: How many more prerun correct catches we need
    
}
@property bool mirrored;    //!< True if we need to mirror output. Initialized during prerun.
@property(weak) IBOutlet NSObject <OutputViewProtocol> *outputView; //!< Assigned in NIB: Displays current output QR code
@property(weak) IBOutlet VideoSelectionView *selectionView;         //!< Assigned in NIB: view that allows selection of input device
@property(weak) IBOutlet id <InputCaptureProtocol> capturer;        //!< Assigned in NIB: video capturer
@property(weak) IBOutlet id <ClockProtocol> clock;                  //!< Assigned in NIB: clock source, usually same as capturer
@property(weak) IBOutlet id <InputVideoFindProtocol> finder;        //!< Assigned in NIB: matches incoming QR codes
@property(weak) IBOutlet id <OutputVideoGenProtocol> genner;        //!< Assigned in NIB: generates QR codes for output

+ (void)initialize;
- (VideoRunManager *)init;  //!< Initializer
-(void)stop;

- (IBAction)startPreMeasuring: (id)sender;  //!< Called when user presses "prepare" button
- (IBAction)stopPreMeasuring: (id)sender;   //!< Internal: stop premeasuring because we have heard enough
- (IBAction)startMeasuring: (id)sender;     //!< Called when user presses "start" button

- (void)triggerNewOutputValue;
- (void) _prerunRecordNoReception;                  //!< Internal: no QR code was received in time during prerun
- (void) _prerunRecordReception: (NSString *)code;  //!< Internal: QR code was received in time during prerun

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

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
@end
