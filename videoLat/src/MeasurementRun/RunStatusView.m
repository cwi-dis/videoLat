//
//  MeasurementRunView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "RunStatusView.h"

@implementation RunStatusView

- (id)initWithFrame:(NSorUIRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.detectCount = @"unknown";
        self.detectAverage = @"unknown";
    }
    return self;
}

- (id)initWithCoder: (NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if (self) {
        self.detectCount = @"unknown";
        self.detectAverage = @"unknown";
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
#ifdef WITH_APPKIT
    assert(self.bPrepare);
#endif
    assert(self.bRun);
    assert(self.bStop);
}

- (void) dealloc
{
}

- (IBAction)update: (id)sender
{
#ifdef WITH_UIKIT
	dispatch_async(dispatch_get_main_queue(), ^{
		self.bCount.text = self.detectCount;
		self.bAverage.text = self.detectAverage;
		});
#else
    self.bCount.stringValue = self.detectCount;
    self.bAverage.stringValue = self.detectAverage;
#endif
}

- (void)drawRect:(NSorUIRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

@end
