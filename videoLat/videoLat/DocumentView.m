//
//  DocumentView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "DocumentView.h"

@implementation DocumentView
@synthesize status;
@synthesize values;
@synthesize distribution;
@synthesize document;


- (void)viewWillDraw
{
	if (self.document == nil) return;
	if (self.document.dataStore) {
		self.status.detectCount = [NSString stringWithFormat: @"%d", self.document.dataStore.count];
		self.status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.document.dataStore.average / 1000.0, document.dataStore.stddev / 1000.0];
		self.status.detectMaxDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.max];
		self.status.detectMinDelay = [NSString stringWithFormat:@"%.3f", self.document.dataStore.min];
	}
    [self.status update:self];
    [super viewWillDraw];
}

@end
