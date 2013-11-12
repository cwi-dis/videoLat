//
//  StatusView.m
//  videoLat
//
//  Created by Jack Jansen on 12/11/13.
//
//

#import "StatusView.h"

@implementation StatusView
@synthesize detectCount;
@synthesize detectAverage;
@synthesize bwString;
@synthesize finderRect;
@synthesize foundQRcode;

- (void)awakeFromNib
{
	detectCount = [NSString stringWithUTF8String: "none"];
	detectCount = [NSString stringWithUTF8String: "-"];
    bwString = [NSString stringWithUTF8String: "none"];
    finderRect = NSMakeRect(0, 0, -1, -1);
	foundQRcode = false;
}

- (void) update: (id)sender
{
    [bDetectCount setStringValue: detectCount];
    [bDetectAverage setStringValue: detectAverage];
    if (foundQRcode) {
        [bDetectCount setTextColor:[NSColor blackColor]];
    } else {
        [bDetectCount setTextColor:[NSColor redColor]];
    }
    if (NSIsEmptyRect(finderRect)) {
        [bFinderRect setStringValue: @"No QR code found yet"];
    } else {
        NSString * loc = [NSString stringWithFormat: @"pos %d,%d size %d,%d", 
            (int)finderRect.origin.x,
            (int)finderRect.origin.y,
            (int)finderRect.size.width,
            (int)finderRect.size.height];
        [bFinderRect setStringValue: loc];
    }
    [bBWstatus setStringValue: bwString];
}

@end
