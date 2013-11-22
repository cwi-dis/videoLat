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

@interface VideoRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
  @private
    IBOutlet VideoSelectionView *selectionView;
    IBOutlet RunStatusView *status;
	IBOutlet VideoOutputView *outputView;
	IBOutlet id <ManagerDelegateProtocol> delegate;
    IBOutlet id <InputCaptureProtocol> capturer;
    id <InputVideoFindProtocol> finder;
    id <OutputVideoGenProtocol> genner;
    IBOutlet RunCollector *collector;
    bool foundQRcode;
    int found_total;
    int found_ok;
    CIImage *current_qrcode;
    bool currentColorIsWhite;
    uint64_t inputStartTime;
	uint64_t inputAddedOverhead;
    uint64_t outputStartTime;
	uint64_t outputAddedOverhead;
    NSString *outputCode;
    bool outputCodeHasBeenReported;
    NSString *lastOutputCode;
    NSString *lastInputCode;
    // Black/white detection
    int blacklevel;
    int whitelevel;
    int nBWdetections;
}
@property(retain) IBOutlet Document *document;
@property bool running;
@property bool useQRcode;
@property bool mirrored;
@property(retain) NSString *measurementTypeName;

- (IBAction)startPreMeasuring: (id)sender;
- (IBAction)startMeasuring: (id)sender;
- (IBAction)stopMeasuring: (id)sender;

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

// Monochrome support
- (void)_mono_showNewData;
- (void)_mono_newInputDone: (bool)isWhite;
- (void)_mono_pollInput;
@end
