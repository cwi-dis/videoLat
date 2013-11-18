//
//  MeasurementRunView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MeasurementRunView : NSView
@property(retain) IBOutlet NSTextField *bCount;
@property(retain) IBOutlet NSTextField *bAverage;

- (void)update;
@end
