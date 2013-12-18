//
//  GraphView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "GraphView.h"
#import "math.h"

static double _RoundUpTo125(double value)
{
    double magnitude;
    magnitude = floor(log10(value));
    value /= pow(10.0, magnitude);

    if (value < 1.0)
        value = 1.0;
    else if (value < 2.0)
        value = 2.0;
    else if (value < 5.0)
        value = 5.0;
    else
        value = 10.0;

    value *= pow(10.0, magnitude);
    return value;
}

static double normFunc(double x, double average, double stddev)
{
    if (stddev == 0) return 0;
    double modx = (x-average) / stddev;
    double ONEOVERSQRT2PI = 0.3989422804014327;
    double phi = ONEOVERSQRT2PI * exp(-modx*modx/2);
    return phi / stddev;
}

@implementation GraphView
@synthesize color;
@synthesize maxXscale;
@synthesize maxYscale;
@synthesize maxXformat;
@synthesize maxYformat;
@synthesize showAverage;
@synthesize showNormal;

- (GraphView *)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
	if (self) {
		self.color = [NSColor blueColor];
		self.maxXscale = [NSNumber numberWithInt:1];
		self.maxYscale = [NSNumber numberWithInt:1];
		self.maxXformat = @"%f";
		self.maxYformat = @"%f";
        self.showAverage = NO;
        self.showNormal = NO;
	}
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    if (self.source == nil || [self.source count] == 0) {
        NSLog(@"Empty document for graph\n");
        return;
    }
    NSRect dstRect = [self bounds];
	[[NSColor whiteColor] set];
	NSRectFill(dstRect);

	[[NSColor blackColor] set];
    NSBezierPath *axis = [NSBezierPath bezierPath];
	[axis moveToPoint: NSMakePoint(dstRect.origin.x, dstRect.origin.y + dstRect.size.height)];
	[axis lineToPoint: dstRect.origin];
	[axis lineToPoint: NSMakePoint(dstRect.origin.x+ dstRect.size.width, dstRect.origin.y)];
	[axis stroke];
	
    CGFloat width = NSWidth(dstRect);
    CGFloat height = NSHeight(dstRect);
    
    // Determine X scale. Start at zero, unless we get less than a pixel per value,
    // then we discard the oldest data (lowest X indices)
    int minX = 0;
    int maxX = self.source.count-1;
    CGFloat maxXaxis = (CGFloat)_RoundUpTo125(maxX);
    CGFloat xPixelPerUnit = width / (CGFloat)(maxXaxis-minX);
    if (xPixelPerUnit < 1.0) {
        // Don't show the left bit
        minX = (maxX - (int)width);
        maxXaxis = maxX;
        xPixelPerUnit = 1;
    }
    if (minX < 0) minX = 0;
    
    // Determine Y scale. Go from 0 to at least max, but round up to 1/2/5 first digit.
    CGFloat minY = self.source.min;
	if (minY > 0) minY = 0;
    CGFloat maxY = self.source.max;
    CGFloat maxYaxis = (CGFloat)_RoundUpTo125(maxY);

    CGFloat yPixelPerUnit = (maxYaxis-minY) / height;
    if (yPixelPerUnit == 0) yPixelPerUnit = 1;

	if (self.bMaxX) self.bMaxX.stringValue = [NSString stringWithFormat:self.maxXformat, self.source.maxXaxis * [self.maxXscale floatValue]];
	if (self.bMaxY) self.bMaxY.stringValue = [NSString stringWithFormat:self.maxYformat, maxYaxis * [self.maxYscale floatValue]];

    if (1 || VL_DEBUG) NSLog(@"%d < x < %d (scale=%f, axis=%f) %f < y < %f (scale=%f, axis=%f)\n", minX, maxX, xPixelPerUnit, maxXaxis, minY, maxY, yPixelPerUnit, maxYaxis);
    
    // Compute the closed path
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGFloat oldX = minX, oldY = 0;
    CGFloat newX = oldX, newY;

    [path moveToPoint: NSMakePoint(oldX, oldY)];
    int i;
    for (i=minX; i<=maxX; i++) {
        newX = oldX + xPixelPerUnit;
		CGFloat value = [[self.source valueForIndex:i] doubleValue];
        newY = (value - minY) / yPixelPerUnit;
        [path lineToPoint: NSMakePoint(oldX, newY)];
        [path lineToPoint: NSMakePoint(newX, newY)];
        if (VL_DEBUG) NSLog(@"point %f, %f", newX, newY);
        oldX = newX;
    }
    [path lineToPoint: NSMakePoint(newX, 0)];
    [path closePath];
    
    [self.color set];
    [path fill];
    [path stroke];
    
    // Draw the average, if wanted
    if (self.showAverage) {
        double average = self.source.average;
        NSColor *averageColor = [self.color shadowWithLevel:0.5];
        path = [NSBezierPath bezierPath];
        [path moveToPoint: NSMakePoint(dstRect.origin.x, (average-minY) / yPixelPerUnit)];
        [path lineToPoint: NSMakePoint(dstRect.origin.x+dstRect.size.width, (average-minY) / yPixelPerUnit)];
        [averageColor set];
        [path stroke];
    }
    if (self.showNormal) {
	   // Draw the cumulative distribution of the real data
		NSColor *cumulativeColor = [self.color shadowWithLevel:0.5];
		NSBezierPath *cumulativePath = [NSBezierPath bezierPath];
		oldX = minX;
		CGFloat oldCumulativeY = 0;
		newX = oldX;
		CGFloat newCumulativeY;
		[cumulativePath moveToPoint: NSMakePoint(oldX, oldCumulativeY)];
		int i;
		for (i=minX; i<=maxX; i++) {
			newX = oldX + xPixelPerUnit;
			CGFloat value = [[self.source valueForIndex:i] doubleValue];
			newCumulativeY = oldCumulativeY + value;
			[cumulativePath lineToPoint: NSMakePoint(oldX, newCumulativeY*height)];
			[cumulativePath lineToPoint: NSMakePoint(newX, newCumulativeY*height)];
			oldX = newX;
			oldCumulativeY = newCumulativeY;
		}
		[cumulativePath lineToPoint: NSMakePoint(newX, height)];
        [cumulativeColor set];
        [cumulativePath stroke];

		// Draw the cumulative normal distribution for the given average and stddev
        double average = self.source.average;
        double stddev = self.source.stddev;
        double step = self.source.maxXaxis / dstRect.size.width;
		double cumvalue = 0;
        NSColor *normalColor = [self.color highlightWithLevel:0.5];
        path = [NSBezierPath bezierPath];
        [path moveToPoint: NSMakePoint(dstRect.origin.x, cumvalue * height)];
        for (int xindex=1; xindex <dstRect.size.width; xindex++) {
            double x = xindex * step;
            //NSLog(@"%d normFunc(%f, %f, %f) = %f", xindex, x, average, stddev, normFunc(x, average, stddev));
            double value = normFunc(x+step/2, average, stddev);
			cumvalue = cumvalue + (value*step);
            //NSLog(@"(%f, %f)", x, y);
            [path lineToPoint: NSMakePoint(dstRect.origin.x+xindex, cumvalue*height)];
        }
        [normalColor set];
        [path stroke];
    }
}

@end
