//
//  DocumentView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "DocumentView.h"

@implementation DocumentView

- (DocumentView *) init
{
    self = [super init];
    dataStore = nil;
    dataDistribution = nil;
}

- (void)awakeFromNib
{
    baseName = @"videoLat";
}

- (void)viewWillDraw
{
	status.detectCount = [NSString stringWithFormat: @"%d (after trimming 5%%)", dataStore.count];
	status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", dataStore.average / 1000.0, dataStore.stddev / 1000.0];
    [status update:self];
    [super viewWillDraw];
}

- (IBAction)export: (id)sender
{
    
	NSString *csvData = [[dataStore asCSVString] autorelease];
    NSString *fileName = [NSString stringWithFormat:@"/tmp/%@-measurements.csv", baseName];
	[csvData writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
	
	csvData = [[dataDistribution asCSVString] autorelease];
    fileName = [NSString stringWithFormat:@"/tmp/%@-distribution.csv", baseName];
	[csvData writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];    
}

- (IBAction)save: (id)sender
{
    NSString *fileName = [NSString stringWithFormat:@"/tmp/%@.videoLat", baseName];
 	[NSKeyedArchiver archiveRootObject: dataStore toFile: fileName];
}
@end
