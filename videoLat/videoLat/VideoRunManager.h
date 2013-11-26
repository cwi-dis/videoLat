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
#import "RunCollector.h"
#import "protocols.h"
#import "Document.h"
#import "BaseRunManager.h"

@interface VideoRunManager : BaseRunManager {
	IBOutlet id <ManagerDelegateProtocol> delegate;
    IBOutlet RunCollector *collector;
	IBOutlet VideoOutputView *outputView;
    IBOutlet RunTypeView *measurementMaster;
    IBOutlet RunStatusView *statusView;
    IBOutlet VideoSelectionView *selectionView;
    IBOutlet id <InputCaptureProtocol> capturer;

    id <InputVideoFindProtocol> finder;
    id <OutputVideoGenProtocol> genner;

    uint64_t outputStartTime;       // When the last output was displayed
	uint64_t outputAddedOverhead;   // Computed overhead from outputStartTime to display time
    uint64_t inputStartTime;        // When last input was read
	uint64_t inputAddedOverhead;    // Computed overhead to be subtracted from inputStartTime
    NSString *outputCode;           // Current code on the display
    NSString *lastOutputCode;       // Previous code on the display
    NSString *lastInputCode;        // last input code decyphered
    bool outputCodeHasBeenReported; // False when output code generated, true when it has been reported to the collector

    CIImage *current_qrcode;        // Current code as a CIImage
}
@property(retain) IBOutlet Document *document;
@property bool mirrored;

+ (void)initialize;
- (VideoRunManager *)init;
- (void)selectMeasurementType: (NSString *)typeName;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)stopPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;
//- (IBAction)stopMeasuring: (id)sender;

- (void)reportDataCapturer: (id)capt;

- (void)_triggerNewOutputValue;

// MeasurementOutputManagerProtocol
- (CIImage *)newOutputStart;
- (void)newOutputDone;
- (void)updateOutputOverhead: (double)deltaT;

// MeasurementInputManagerProtocol
- (void)setFinderRect: (NSRect)theRect;
- (void)newInputStart;
- (void)updateInputOverhead: (double)deltaT;
- (void)newInputDone;
- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size;
@end
