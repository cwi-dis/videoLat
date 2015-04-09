///
///  @file DocumentDescriptionView.h
///  @brief Defines the DocumentDescriptionView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "compat.h"
#import "DeviceDescriptionView.h"
#import "MeasurementDataStore.h"

///
/// Subclass of NSView that displays all metadata of a measurement run, and allows
/// changing of some of it.
///
@interface DocumentDescriptionView
#ifdef WITH_UIKIT
	: UIView
#else
	: NSView
#endif
{
}
#ifdef WITH_UIKIT
@property(weak) IBOutlet UILabel *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet DeviceDescriptionView *vInput;
@property(weak) IBOutlet DeviceDescriptionView *vOutput;
@property(weak) IBOutlet UILabel *bDate; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet UIButton *bOpenCalibration; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bCalibrationLabel; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet UILabel *bDetectMaxDelay; //!< Reference to UI element
#else
@property(weak) IBOutlet NSTextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet DeviceDescriptionView *vInput;
@property(weak) IBOutlet DeviceDescriptionView *vOutput;
@property(weak) IBOutlet NSTextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSButton *bOpenCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bCalibrationLabel; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMaxDelay; //!< Reference to UI element
#endif
@property(strong) MeasurementDataStore *modelObject;
//@property(strong) NSString *measurementType;    //!< Current value of metadata item
//@property(strong) NSString *date;    //!< Current value of metadata item
//@property(strong) NSString *description;    //!< Current value of metadata item
//@property(strong) NSString *detectCount;    //!< Current value of metadata item
//@property(strong) NSString *missCount;    //!< Current value of metadata item
//@property(strong) NSString *detectAverage;    //!< Current value of metadata item
//@property(strong) NSString *detectMinDelay;    //!< Current value of metadata item
//@property(strong) NSString *detectMaxDelay;    //!< Current value of metadata item
/// Update UI elements to reflect values in metadata items

- (void) update: (id)sender;
@end
