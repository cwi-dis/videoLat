//
//  OutputManager.h
//
//  Created by Jack Jansen on 27-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SettingsView.h"
#import "StatusView.h"
#import "protocols.h"

@interface Manager : NSObject <SettingsChangedProtocol, MeasurementOutputManagerProtocol, MeasurementInputManagerProtocol> {
  @private
    IBOutlet SettingsView *settings;
    IBOutlet StatusView *status;
	IBOutlet id <OutputViewProtocol> outputView;
	IBOutlet id <ManagerDelegateProtocol> delegate;
    IBOutlet id <DataCaptureProtocol> capturer;
    id <FindProtocol> finder;
    id <GenProtocol> genner;
    IBOutlet id <DataCollectorProtocol> collector;
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

@property(readonly) bool running;

- (void)startMeasuring;
- (void)stopMeasuring;

- (void)reportDataCapturer: (id)capt;

- (void)_triggerNewOutputValue;


// SettingsChangedProtocol
- (void)settingsChanged;

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
