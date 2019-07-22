///
///  @file LevelStatusView.h
///  @brief Defines LevelStatusView object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "protocols.h"

///
/// An NSView or UIView that shows information such as number of detections and average delay
/// while a measurement run is underway.
/// This view usually lives together with RunTypeView, and is instantiated from
/// the NewMeasurement.xib NIB file.
///
@interface LevelStatusView
#ifdef WITH_UIKIT
: NSorUIView
#else
: NSorUIView
#endif

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
@end
