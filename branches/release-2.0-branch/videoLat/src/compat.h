///
///  @file compat.h
///  @brief Defines, typedefs and functions to handle iOS/OSX compatibility.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#ifndef videoLat_iOS_compat_h
#define videoLat_iOS_compat_h

#import <Foundation/Foundation.h>

//@{
/// Defines and typedefs to ease iOS/OSX compatibility.
/// These forestall a large number of ifdefs in the code by
/// resolving to either an AppKit or a UIKit type or function.
#if TARGET_OS_IPHONE
#define WITH_UIKIT
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
typedef UIApplication NSorUIApplication;
typedef CGRect NSorUIRect;
typedef UIPickerView NSorUIPopUpButton;
typedef UIButton NSorUIButton;
typedef UISwitch NSorUISwitch;
typedef UITextField NSorUITextField;
typedef UILabel NSorUILabel;
typedef UIView NSorUIView;
typedef UIProgressView NSorUILevelIndicator;
typedef UISlider NSorUISlider;
@class MeasurementContainerViewController;
typedef MeasurementContainerViewController MeasurementMasterType;
typedef UIColor NSorUIColor;
typedef UIBezierPath NSorUIBezierPath;

#define NSorUIMakePoint CGPointMake
#define NSorUIWidth CGRectGetWidth
#define NSorUIHeight CGRectGetHeight
#define NSorUIRectFill UIRectFill
#define NSorUIMakeRect CGRectMake
#define NSorUIMidX CGRectGetMidX
#define NSorUIMidY CGRectGetMidY
#define NSRectFromCGRect(x) (x)
#else
#define WITH_APPKIT
typedef NSApplication NSorUIApplication;
typedef NSRect NSorUIRect;
typedef NSPopUpButton NSorUIPopUpButton;
typedef NSButton NSorUIButton;
typedef NSButton NSorUISwitch;
typedef NSTextField NSorUITextField;
typedef NSTextField NSorUILabel;
typedef NSView NSorUIView;
typedef NSLevelIndicator NSorUILevelIndicator;
typedef NSSlider NSorUISlider;
@class RunManagerView;
typedef RunManagerView MeasurementMasterType;
typedef NSColor NSorUIColor;
typedef NSBezierPath NSorUIBezierPath;

#define NSorUIMakePoint NSMakePoint
#define NSorUIWidth NSWidth
#define NSorUIHeight NSHeight
#define NSorUIRectFill NSRectFill
#define NSorUIMakeRect NSMakeRect
#define NSorUIMidX NSMidX
#define NSorUIMidY NSMidY
#endif
//@}

#ifdef __cplusplus
extern "C" {
#endif

/// A monotonic clock.
/// @return The current system time in microseconds, since an unknown (but stable) epoch.
uint64_t monotonicMicroSecondClock();

/// Present an error message to the user.
/// @param error The information to present in the error message.
void showErrorAlert(NSError *error);

/// Present a warning dialog to the user.
/// @param warning The message to show.
void showWarningAlert(NSString *warning);

#ifdef __cplusplus
};
#endif

#endif
