//
//  MeasurementRunView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunStatusView.h"

@implementation RunStatusView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.detectCount = @"unknown";
        self.detectAverage = @"unknown";
    }
    return self;
}

- (void) dealloc
{
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
