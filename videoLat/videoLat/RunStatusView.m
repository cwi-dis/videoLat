//
//  MeasurementRunView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "RunStatusView.h"

@implementation RunStatusView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)update: (id)sender
{
    self.bCount.stringValue = self.detectCount;
    self.bAverage.stringValue = self.detectAverage;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
