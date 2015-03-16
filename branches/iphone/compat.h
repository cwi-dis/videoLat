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
#define NSorUIApplication UIApplication
#define NSorUIRect CGRect
#define NSorUIPopUpButton UIPickerView
#define NSorUIButton UIButton
#define NSorUISwitch UISwitch
#define NSorUITextField UITextField
#define NSorUILabel UILabel
#define NSorUIView UIView
#define NSorUILevelIndicator UIProgressView
#define NSorUISlider UISlider
#define MeasurementMasterType MeasurementContainerViewController
#define NSorUIColor UIColor
#define NSorUIBezierPath UIBezierPath
#define NSorUIMakePoint CGPointMake
#define NSorUIWidth CGRectGetWidth
#define NSorUIHeight CGRectGetHeight
#define NSorUIRectFill UIRectFill
#else
#define WITH_APPKIT
#define NSorUIApplication NSApplication
#define NSorUIRect NSRect
#define NSorUIPopUpButton NSPopUpButton
#define NSorUIButton NSButton
#define NSorUISwitch NSButton
#define NSorUITextField NSTextField
#define NSorUILabel NSTextField
#define NSorUIView NSView
#define NSorUILevelIndicator NSLevelIndicator
#define NSorUISlider NSSlider
#define MeasurementMasterType RunManagerView
#define NSorUIColor NSColor
#define NSorUIBezierPath NSBezierPath
#define NSorUIMakePoint NSMakePoint
#define NSorUIWidth NSWidth
#define NSorUIHeight NSHeight
#define NSorUIRectFill NSRectFill
#endif

void showErrorAlert(NSError *error);
void showWarningAlert(NSString *warning);

#endif
