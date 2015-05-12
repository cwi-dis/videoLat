///
///  @file VideoMonoRunManager.h
///  @brief Implements video black/white measurements.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "VideoRunManager.h"
#import "compat.h"

///
/// Subclass of VideoRunManager that uses 100% black/white pictures to measure delay.
/// Overrides a minimal number of methods to handle black/white, a lot of the other
/// changes are made through the NIB file. Compatible with HardwareRunManager.
///
@interface VideoMonoRunManager : VideoRunManager {
    // Black/white detection
    int minInputLevel;             //!< Internal: darkest color seen during prerun
    int maxInputLevel;             //!< Internal: lightest color seen during prerun
    NSorUIRect sensitiveArea;       //!< Internal: where we look for black/white in the input signal.
}

#ifdef WITH_UIKIT
@property(weak) IBOutlet UISwitch *bInputValue;             //!< UI element: feedback on light/no light detected
@property(weak) IBOutlet UILabel *bInputNumericValue;   //!< UI element: feedback on analog input received
@property(weak) IBOutlet UILabel *bInputNumericMinValue;   //!< UI element: feedback on analog input received
@property(weak) IBOutlet UILabel *bInputNumericMaxValue;   //!< UI element: feedback on analog input received
#else
@property(weak) IBOutlet NSButton *bInputValue;             //!< UI element: feedback on light/no light detected
@property(weak) IBOutlet NSTextField *bInputNumericValue;   //!< UI element: feedback on analog input received
@property(weak) IBOutlet NSTextField *bInputNumericMinValue;   //!< UI element: feedback on analog input received
@property(weak) IBOutlet NSTextField *bInputNumericMaxValue;   //!< UI element: feedback on analog input received
#endif

+ (void)initialize;
- (VideoMonoRunManager *)init;

- (CIImage *)newOutputStart;

@end

