//
//  DocumentDescriptionView.h
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import <Cocoa/Cocoa.h>

///
/// Subclass of NSView that displays all metadata of a measurement run, and allows
/// changing of some of it.
///
@interface DocumentDescriptionView : NSView {
}
@property(weak) IBOutlet NSTextField *bMeasurementType; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMachine; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bInputDevice; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bOutputDevice; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDate; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bLocation; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDescription; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bMissCount; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectAverage; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMinDelay; //!< Reference to UI element
@property(weak) IBOutlet NSTextField *bDetectMaxDelay; //!< Reference to UI element

@property(strong) NSString *measurementType;    //!< Current value of metadata item
@property(strong) NSString *machine;    //!< Current value of metadata item
@property(strong) NSString *inputDevice;    //!< Current value of metadata item
@property(strong) NSString *outputDevice;    //!< Current value of metadata item
@property(strong) NSString *date;    //!< Current value of metadata item
@property(strong) NSString *location;    //!< Current value of metadata item
@property(strong) NSString *description;    //!< Current value of metadata item
@property(strong) NSString *detectCount;    //!< Current value of metadata item
@property(strong) NSString *missCount;    //!< Current value of metadata item
@property(strong) NSString *detectAverage;    //!< Current value of metadata item
@property(strong) NSString *detectMinDelay;    //!< Current value of metadata item
@property(strong) NSString *detectMaxDelay;    //!< Current value of metadata item

/// Update UI elements to reflect values in metadata items
- (void) update: (id)sender;
@end
