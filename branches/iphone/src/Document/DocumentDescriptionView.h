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
@property(weak) IBOutlet UITextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet DeviceDescriptionView *vInput;
@property(weak) IBOutlet DeviceDescriptionView *vOutput;
@property(weak) IBOutlet UITextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet UITextField *bDetectMaxDelay; //!< Reference to UI element
#else
@property(weak) IBOutlet NSTextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet DeviceDescriptionView *vInput;
@property(weak) IBOutlet DeviceDescriptionView *vOutput;
@property(weak) IBOutlet NSTextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMaxDelay; //!< Reference to UI element
#endif

@property(strong) NSString *measurementType;    //!< Current value of metadata item
@property(strong) NSString *date;    //!< Current value of metadata item
@property(strong) NSString *description;    //!< Current value of metadata item
@property(strong) NSString *detectCount;    //!< Current value of metadata item
@property(strong) NSString *missCount;    //!< Current value of metadata item
@property(strong) NSString *detectAverage;    //!< Current value of metadata item
@property(strong) NSString *detectMinDelay;    //!< Current value of metadata item
@property(strong) NSString *detectMaxDelay;    //!< Current value of metadata item
/// Update UI elements to reflect values in metadata items

- (void) update: (id)sender;
@end
