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
@interface DocumentDescriptionView : NSorUIView {
}
@property(weak) IBOutlet NSorUITextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet DeviceDescriptionView *vInput;
@property(weak) IBOutlet DeviceDescriptionView *vOutput;
@property(weak) IBOutlet NSorUITextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectMaxDelay; //!< Reference to UI element

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
