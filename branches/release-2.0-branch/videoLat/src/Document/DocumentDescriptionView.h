///
///  @file DocumentDescriptionView.h
///  @brief Defines the DocumentDescriptionView object.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
@property(strong) MeasurementDataStore *modelObject;	//!< The object for which we display the data.

- (void) update: (id)sender;	//!< Called when the UI should be updated.

- (void)controlTextDidChange:(NSNotification *)aNotification;   //!< Called when description in status view has changed, updates the document

@end
