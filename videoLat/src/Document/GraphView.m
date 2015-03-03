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
    if (value == 0)
        return 0;
	double sign;
	if (value < 0) {
		value = -value;
		sign = -1;
	} else {
		sign = 1;
	}
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
    return sign*value;
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
@synthesize xLabelScaleFactor;
@synthesize yLabelScaleFactor;
@synthesize xLabelFormat;
@synthesize yLabelFormat;
@synthesize showAverage;
@synthesize showNormal;

- (GraphView *)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
	if (self) {
		self.color = [NSColor blueColor];
		self.xLabelScaleFactor = [NSNumber numberWithInt:1];
		self.yLabelScaleFactor = [NSNumber numberWithInt:1];
		self.xLabelFormat = @"%f";
		self.yLabelFormat = @"%f";
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
    CGFloat minX = 0;
    CGFloat maxX = self.source.maxXaxis;
	CGFloat minXaxis = (CGFloat)_RoundUpTo125(minX);
    CGFloat maxXaxis = (CGFloat)_RoundUpTo125(maxX);
    CGFloat xPixelPerUnit = width / (CGFloat)(maxXaxis-minXaxis);
#if 0
    if (xPixelPerUnit < 1.0) {
        // Don't show the left bit
        minX = (maxX - (int)width);
        maxXaxis = maxX;
		minXaxis = minX;
        xPixelPerUnit = 1;
    }
#endif
#if 0
    if (minX < 0) minX = 0;
#endif

    // Determine Y scale. Go from at least 0 to at least max, but round up to 1/2/5 first digit.
    CGFloat minY = self.source.min;
	if (minY > 0) minY = 0;
    CGFloat maxY = self.source.max;
    CGFloat minYaxis = (CGFloat)_RoundUpTo125(minY);
    CGFloat maxYaxis = (CGFloat)_RoundUpTo125(maxY);

    CGFloat yPixelPerUnit = height / (maxYaxis-minYaxis);
    if (yPixelPerUnit == 0) yPixelPerUnit = 1;
	NSString *tmp = [NSString stringWithFormat:self.xLabelFormat, minXaxis * [self.xLabelScaleFactor floatValue]];
	if (self.bMinX) self.bMinX.stringValue = tmp;
	tmp = [NSString stringWithFormat:self.xLabelFormat, maxXaxis * [self.xLabelScaleFactor floatValue]];
	if (self.bMaxX) self.bMaxX.stringValue = tmp;
	tmp = [NSString stringWithFormat:self.yLabelFormat, minYaxis * [self.yLabelScaleFactor floatValue]];
	if (self.bMinY) self.bMinY.stringValue = tmp;
	tmp = [NSString stringWithFormat:self.yLabelFormat, maxYaxis * [self.yLabelScaleFactor floatValue]];
	if (self.bMaxY) self.bMaxY.stringValue = tmp;

    if (1||VL_DEBUG) NSLog(@"%f < x < %f (scale=%f, axis=%f..%f) %f < y < %f (scale=%f, axis=%f..%f)\n", minX, maxX, xPixelPerUnit, minXaxis, maxXaxis, minY, maxY, yPixelPerUnit, minYaxis, maxYaxis);

	NSBezierPath *path;
	// Draw the x=0 and y=0 lines, if visible
	if (minXaxis < 0) {
		NSColor *axisColor = [NSColor blackColor];
		path = [NSBezierPath bezierPath];
		[path moveToPoint: NSMakePoint(dstRect.origin.x, (0-minY)/ yPixelPerUnit)];
        [path lineToPoint: NSMakePoint(dstRect.origin.x+dstRect.size.width, (0-minY) / yPixelPerUnit)];
        [axisColor set];
        [path stroke];
		path = nil;
	}
	if (minYaxis < 0) {
		NSColor *axisColor = [NSColor blackColor];
		path = [NSBezierPath bezierPath];
		[path moveToPoint: NSMakePoint((0-minX)/xPixelPerUnit, dstRect.origin.y)];
        [path lineToPoint: NSMakePoint((0-minX)/yPixelPerUnit, dstRect.origin.y+dstRect.size.height) ];
        [axisColor set];
        [path stroke];
		path = nil;
	}

    // Compute the closed path
    path = [NSBezierPath bezierPath];
    CGFloat oldX = minXaxis, oldY = 0;
    CGFloat newX = oldX, newY;

    [path moveToPoint: NSMakePoint(oldX, oldY)];
    int i;
	int minXindex = (int)(minX / [self.source binSize]);
	assert(minXindex >= 0);
	int maxXindex = (int)(maxX / [self.source binSize]);
    for (i=minXindex; i<=maxXindex; i++) {
        newX = oldX + xPixelPerUnit*[self.source binSize];
		CGFloat value = 0;
		if (i < maxXindex) value = [[self.source valueForIndex:i] doubleValue];
        newY = (value - minYaxis) * yPixelPerUnit;
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
        [path moveToPoint: NSMakePoint(dstRect.origin.x, (average-minYaxis) * yPixelPerUnit)];
        [path lineToPoint: NSMakePoint(dstRect.origin.x+dstRect.size.width, (average-minYaxis) * yPixelPerUnit)];
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
		for (i=minXindex; i<=maxXindex; i++) {
			newX = oldX + xPixelPerUnit*[self.source binSize];
			CGFloat value = 0;
			if (i < maxXindex) value = [[self.source valueForIndex:i] doubleValue];
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
        double step = (maxXaxis - minXaxis) / dstRect.size.width;
		double cumvalue = 0;
        NSColor *normalColor = [self.color highlightWithLevel:0.5];
        path = [NSBezierPath bezierPath];
        [path moveToPoint: NSMakePoint(dstRect.origin.x, cumvalue * height)];
        for (int xindex=1; xindex <dstRect.size.width; xindex++) {
            double x = minXaxis + (xindex * step);
            //NSLog(@"%d normFunc(%f, %f, %f) = %f", xindex, x, average, stddev, normFunc(x, average, stddev));
            double value = normFunc(x+step/2, average, stddev);
			cumvalue = cumvalue + (value*step);
            //NSLog(@"(%f, %f)", x, y);
            [path lineToPoint: NSMakePoint(dstRect.origin.x+xindex, cumvalue*height)];
        }
        [normalColor set];
        [path stroke];
		// And draw the average
		path = [NSBezierPath bezierPath];
		double value = (average-minX)*xPixelPerUnit;
		[path moveToPoint: NSMakePoint(value, dstRect.origin.y)];
        [path lineToPoint: NSMakePoint(value, dstRect.origin.y+dstRect.size.height) ];
        [cumulativeColor set];
        [path stroke];
		path = nil;
    }
}

@end
