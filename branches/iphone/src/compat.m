//
//  compat.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 16/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "compat.h"
#ifdef WITH_UIKIT
#else
#import "RunManagerView.h"
#endif

void showErrorAlert(NSError *error) {
#ifdef WITH_UIKIT
	[[[UIAlertView alloc] initWithTitle:error.localizedDescription
                            message:error.localizedRecoverySuggestion
                           delegate:nil
                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                  otherButtonTitles:nil, nil] show];
#else
	NSAlert *alert = [NSAlert alertWithError:error];
	[alert runModal];
#endif
}

void showWarningAlert(NSString *warning) {
#ifdef WITH_UIKIT
	[[[UIAlertView alloc] initWithTitle:@"Warning"
                            message:warning
                           delegate:nil
                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                  otherButtonTitles:nil, nil] show];
#else
    NSAlert *alert = [NSAlert alertWithMessageText:@"Warning" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", warning];
    [alert runModal];
#endif
}

void keepClassesAliveHack()
{
	[NSorUIApplication class];
	[NSorUIPopUpButton class];
	[NSorUIButton class];
	[NSorUISwitch class];
	[NSorUITextField class];
	[NSorUILabel class];
	[NSorUIView class];
	[NSorUILevelIndicator class];
	[NSorUISlider class];
	[MeasurementMasterType class];
	[NSorUIColor class];
	[NSorUIBezierPath class];
}