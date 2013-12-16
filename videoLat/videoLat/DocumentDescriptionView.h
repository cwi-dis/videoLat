//
//  StatusView.h
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface DocumentDescriptionView : NSView {
}
@property(weak) IBOutlet NSTextField *bMeasurementType;
@property(weak) IBOutlet NSTextField *bMachine;
@property(weak) IBOutlet NSTextField *bInputDevice;
@property(weak) IBOutlet NSTextField *bOutputDevice;
@property(weak) IBOutlet NSTextField *bDate;
@property(weak) IBOutlet NSTextField *bLocation;
@property(weak) IBOutlet NSTextField *bDescription;
@property(weak) IBOutlet NSTextField *bDetectCount;
@property(weak) IBOutlet NSTextField *bDetectAverage;
@property(weak) IBOutlet NSTextField *bDetectMinDelay;
@property(weak) IBOutlet NSTextField *bDetectMaxDelay;

@property(strong) NSString *measurementType;
@property(strong) NSString *machine;
@property(strong) NSString *inputDevice;
@property(strong) NSString *outputDevice;
@property(strong) NSString *date;
@property(strong) NSString *location;
@property(strong) NSString *description;
@property(strong) NSString *detectCount;
@property(strong) NSString *detectAverage;
@property(strong) NSString *detectMinDelay;
@property(strong) NSString *detectMaxDelay;

- (void) update: (id)sender;
@end
