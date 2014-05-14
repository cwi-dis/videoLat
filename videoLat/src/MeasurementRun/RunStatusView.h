//
//  MeasurementRunView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>

@interface RunStatusView : NSView
@property(weak) IBOutlet NSButton *bStop;

@property(weak) IBOutlet NSTextField *bCount;
@property(weak) IBOutlet NSTextField *bAverage;

@property(strong) NSString *detectCount;
@property(strong) NSString *detectAverage;

- (IBAction)update: (id)sender;
@end
