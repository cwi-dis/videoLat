//
//  StatusView.h
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import <Cocoa/Cocoa.h>

@interface StatusView : NSView {
    IBOutlet NSTextField *bDetectCount;
    IBOutlet NSTextField *bDetectAverage;
    IBOutlet NSTextField *bFinderRect;
    IBOutlet NSTextField *bBWstatus;

    NSString *detectCount;
    NSString *detectAverage;
    NSRect finderRect;
    NSString *bwString;
    bool foundQRcode;
}
@property(retain) NSString *detectCount;
@property(retain) NSString *detectAverage;
@property(retain) NSString *bwString;
@property(assign) NSRect finderRect;
@property bool foundQRcode;

- (void) update: (id)sender;
@end
