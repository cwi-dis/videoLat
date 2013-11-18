//
//  StatusView.h
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView {
}
@property(retain) IBOutlet NSTextField *bMeasurementType;
@property(retain) IBOutlet NSTextField *bInputDevice;
@property(retain) IBOutlet NSTextField *bOutputDevice;
@property(retain) IBOutlet NSTextField *bDate;
@property(retain) IBOutlet NSTextField *bLocation;
@property(retain) IBOutlet NSTextField *bDescription;
@property(retain) IBOutlet NSTextField *bDetectCount;
@property(retain) IBOutlet NSTextField *bDetectAverage;
@property(retain) IBOutlet NSTextField *bDetectMinDelay;
@property(retain) IBOutlet NSTextField *bDetectMaxDelay;

@property(retain) NSString *measurementType;
@property(retain) NSString *inputDevice;
@property(retain) NSString *outputDevice;
@property(retain) NSString *date;
@property(retain) NSString *location;
@property(retain) NSString *description;
@property(retain) NSString *detectCount;
@property(retain) NSString *detectAverage;
@property(retain) NSString *detectMinDelay;
@property(retain) NSString *detectMaxDelay;

- (void) update: (id)sender;
@end
