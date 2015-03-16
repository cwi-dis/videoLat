///
///  @file DocumentDescriptionView.h
///  @brief Defines the DocumentDescriptionView object.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import "compat.h"
///
/// Subclass of NSView that displays all metadata of a measurement run, and allows
/// changing of some of it.
///
@interface DocumentDescriptionView : NSorUIView {
}
@property(weak) IBOutlet NSorUITextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bInputMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bInputMachine; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bInputLocation; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bInputDevice; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bInputCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bOutputMachineTypeID; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bOutputMachine; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bOutputLocation; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bOutputDevice; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bOutputCalibration; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet NSorUITextField *bDetectMaxDelay; //!< Reference to UI element

@property(weak) IBOutlet NSorUIButton *bOpenInputCalibration;
@property(weak) IBOutlet NSorUIButton *bOpenOutputCalibration;

@property(strong) NSString *measurementType;    //!< Current value of metadata item
@property(strong) NSString *inputMachineTypeID;    //!< Current value of metadata item
@property(strong) NSString *inputMachine;    //!< Current value of metadata item
@property(strong) NSString *inputLocation;    //!< Current value of metadata item
@property(strong) NSString *inputDevice;    //!< Current value of metadata item
@property(strong) NSString *inputCalibration;    //!< Current value of metadata item
@property(strong) NSString *outputMachineTypeID;    //!< Current value of metadata item
@property(strong) NSString *outputMachine;    //!< Current value of metadata item
@property(strong) NSString *outputLocation;    //!< Current value of metadata item
@property(strong) NSString *outputDevice;    //!< Current value of metadata item
@property(strong) NSString *outputCalibration;    //!< Current value of metadata item
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
