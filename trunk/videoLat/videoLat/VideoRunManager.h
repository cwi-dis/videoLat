//
//  OutputManager.h
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RunTypeView.h"
#import "RunStatusView.h"
#import "VideoSelectionView.h"
#import "VideoOutputView.h"
#import "protocols.h"
#import "Document.h"
#import "BaseRunManager.h"

@interface VideoRunManager : BaseRunManager {

    id <InputVideoFindProtocol> finder;
    id <OutputVideoGenProtocol> genner;

    uint64_t outputStartTime;       // When the last output was displayed
    uint64_t prerunOutputStartTime;       // Same, but not reset when reported (for prerun duration checking)
    uint64_t prevOutputStartTime;   // For checking they are monotonously increasing
    NSString *outputCode;           // Current code on the display
    NSString *prevOutputCode;       // Previous code, for dual detections and checking monotonous increase
    CIImage *outputCodeImage;       // Current code as a CIImage

    uint64_t inputStartTime;        // When last input was read
    uint64_t prevInputStartTime;    // When last input was read
    NSString *prevInputCode;         // For checking monotonous increase
    int prevInputCodeDetectionCount;    // Number of times we re-detected a code.
    
    
    uint64_t prerunDelay;           // How log to wait for prerun code finding
    int prerunMoreNeeded;           // How many more prerun correct catches we need
    
}
@property(weak) IBOutlet Document *document;
@property bool mirrored;
@property(weak) IBOutlet id <ManagerDelegateProtocol> delegate;
@property(weak) IBOutlet VideoOutputView *outputView;
@property(weak) IBOutlet RunTypeView *measurementMaster;
@property(weak) IBOutlet RunStatusView *statusView;
@property(weak) IBOutlet VideoSelectionView *selectionView;
@property(strong) IBOutlet id <InputCaptureProtocol> capturer;
@property(weak) IBOutlet id <ClockProtocol> clock;

+ (void)initialize;
- (VideoRunManager *)init;
- (void)selectMeasurementType: (NSString *)typeName;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;
//- (IBAction)stopMeasuring: (id)sender;

- (void)reportDataCapturer: (id)capt;

- (void)_triggerNewOutputValue;
- (void) _prerunRecordNoReception;
- (void) _prerunRecordReception: (NSString *)code;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;

// MeasurementInputManagerProtocol
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
