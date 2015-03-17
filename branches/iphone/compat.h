//
//  compat.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#ifndef videoLat_iOS_compat_h
#define videoLat_iOS_compat_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#define WITH_UIKIT
#define WITH_UIKIT_TEMP
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
#endif

void showErrorAlert(NSError *error);
void showWarningAlert(NSString *warning);

#endif
