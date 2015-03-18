//
//  GraphView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "GraphView.h"
#import "math.h"

#ifdef WITH_UIKIT
// This is gross, I know...
#define stringValue text
#define lineToPoint addLineToPoint
#endif

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

static double _dividerSteps(double minAxis, double maxAxis)
{
	double axisStep = _RoundUpTo125(maxAxis * 1.01) / 10.0;
	if (minAxis < 0) {
		double altAxisStep = _RoundUpTo125(-minAxis *1.01) / 10.0;
		if (altAxisStep > axisStep) axisStep = altAxisStep;
	}
	return axisStep;
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

- (NSObject<GraphDataProviderProtocol> *)modelObject { return _modelObject; }
- (void)setModelObject: (NSObject<GraphDataProviderProtocol> *) modelObject
{
    _modelObject = modelObject;
    [self setNeedsDisplay];
}

- (GraphView *)initWithFrame:(NSorUIRect)frameRect
{
    self = [super initWithFrame:frameRect];
	if (self) {
		self.color = [NSorUIColor blueColor];
		self.xLabelScaleFactor = [NSNumber numberWithInt:1];
		self.yLabelScaleFactor = [NSNumber numberWithInt:1];
		self.xLabelFormat = @"%f";
		self.yLabelFormat = @"%f";
        self.showAverage = NO;
        self.showNormal = NO;
	}
    return self;
}

- (GraphView *)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if (self) {
        self.color = [NSorUIColor blueColor];
        self.xLabelScaleFactor = [NSNumber numberWithInt:1];
        self.yLabelScaleFactor = [NSNumber numberWithInt:1];
        self.xLabelFormat = @"%f";
        self.yLabelFormat = @"%f";
        self.showAverage = NO;
        self.showNormal = NO;
    }
    return self;
}

- (void)drawRect:(NSorUIRect)dirtyRect {
    if (self.modelObject == nil || [self.modelObject count] == 0) {
        NSLog(@"Empty document for graph\n");
        return;
    }
    NSorUIRect dstRect = [self bounds];
#ifdef WITH_UIKIT
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -self.bounds.size.height);
#endif
	[[NSorUIColor whiteColor] set];
	NSorUIRectFill(dstRect);

	[[NSorUIColor blackColor] set];
    NSorUIBezierPath *axis = [NSorUIBezierPath bezierPath];
	[axis moveToPoint: NSorUIMakePoint(dstRect.origin.x, dstRect.origin.y + dstRect.size.height)];
	[axis lineToPoint: dstRect.origin];
	[axis lineToPoint: NSorUIMakePoint(dstRect.origin.x+ dstRect.size.width, dstRect.origin.y)];
	[axis stroke];
	
    CGFloat width = NSorUIWidth(dstRect);
    CGFloat height = NSorUIHeight(dstRect);

    // Determine X scale. Start at zero, unless we get less than a pixel per value,
    // then we discard the oldest data (lowest X indices)
    CGFloat minX = self.modelObject.minXaxis;
    CGFloat maxX = self.modelObject.maxXaxis;
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
    CGFloat minY = self.modelObject.min;
	if (minY > 0) minY = 0;
    CGFloat maxY = self.modelObject.max;
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

    if (VL_DEBUG) NSLog(@"%f < x < %f (scale=%f, axis=%f..%f) %f < y < %f (scale=%f, axis=%f..%f)\n", minX, maxX, xPixelPerUnit, minXaxis, maxXaxis, minY, maxY, yPixelPerUnit, minYaxis, maxYaxis);

	NSorUIBezierPath *path;
	// Draw the x=0 and y=0 lines, if visible
#ifdef WITH_UIKIT
	NSorUIColor *axisColor = [NSorUIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1];
#else
	NSorUIColor *axisColor = [[NSorUIColor whiteColor] shadowWithLevel: 0.3];
#endif
	double gridlineSpacer = _dividerSteps(minYaxis, maxYaxis);
	double gridLinePosition = 0;
	while (gridLinePosition > minYaxis) gridLinePosition -= gridlineSpacer;
	gridLinePosition += gridlineSpacer;
	while (gridLinePosition <= maxYaxis) {
		path = [NSorUIBezierPath bezierPath];
		double value = (gridLinePosition-minYaxis)*yPixelPerUnit;
		[path moveToPoint: NSorUIMakePoint(dstRect.origin.x, value)];
        [path lineToPoint: NSorUIMakePoint(dstRect.origin.x+dstRect.size.width, value)];
        [axisColor set];
        [path stroke];
		path = nil;
		gridLinePosition += gridlineSpacer;
	}
	gridlineSpacer = _dividerSteps(minXaxis, maxXaxis);
	gridLinePosition = 0;
	while (gridLinePosition > minXaxis) gridLinePosition -= gridlineSpacer;
	gridLinePosition += gridlineSpacer;
	while (gridLinePosition <= maxXaxis) {
		path = [NSorUIBezierPath bezierPath];
		double value = (gridLinePosition-minXaxis)*xPixelPerUnit;
		[path moveToPoint: NSorUIMakePoint(value, dstRect.origin.y)];
        [path lineToPoint: NSorUIMakePoint(value, dstRect.origin.y+dstRect.size.height) ];
        [axisColor set];
        [path stroke];
		path = nil;
		gridLinePosition += gridlineSpacer;
	}

    // Compute the closed path
    path = [NSorUIBezierPath bezierPath];
    CGFloat oldX = (minX-minXaxis)*xPixelPerUnit, oldY = -minYaxis*yPixelPerUnit;
    CGFloat newX = oldX, newY;

    [path moveToPoint: NSorUIMakePoint(oldX, oldY)];
    int i;
	int minXindex = 0;
	assert(minXindex >= 0);
	int maxXindex = (int)((maxX-minX) / [self.modelObject binSize]);
    for (i=minXindex; i<=maxXindex; i++) {
        newX = oldX + xPixelPerUnit*[self.modelObject binSize];
		CGFloat value = 0;
		if (i > minXindex && i < maxXindex) value = [[self.modelObject valueForIndex:i] doubleValue];
        newY = (value - minYaxis) * yPixelPerUnit;
        [path lineToPoint: NSorUIMakePoint(oldX, newY)];
        [path lineToPoint: NSorUIMakePoint(newX, newY)];
        if (VL_DEBUG) NSLog(@"point %f, %f", newX, newY);
        oldX = newX;
    }
    [path lineToPoint: NSorUIMakePoint(newX, -minYaxis*yPixelPerUnit)];
    [path closePath];
    
    [self.color set];
    [path fill];
    [path stroke];
    // Draw the average, if wanted
    if (self.showAverage) {
        double average = self.modelObject.average;
#ifdef WITH_UIKIT
		CGFloat h, s, v, alfa;
		[self.color getHue:&h saturation:&s brightness:&v alpha:&alfa];
		NSorUIColor *averageColor = [NSorUIColor colorWithHue:h saturation:s brightness:v*0.5 alpha:alfa];
#else
        NSorUIColor *averageColor = [self.color shadowWithLevel:0.5];
#endif
        path = [NSorUIBezierPath bezierPath];
        [path moveToPoint: NSorUIMakePoint(dstRect.origin.x, (average-minYaxis) * yPixelPerUnit)];
        [path lineToPoint: NSorUIMakePoint(dstRect.origin.x+dstRect.size.width, (average-minYaxis) * yPixelPerUnit)];
        [averageColor set];
        [path stroke];
    }
    if (self.showNormal) {
	   // Draw the cumulative distribution of the real data
#ifdef WITH_UIKIT
		CGFloat h, s, v, alfa;
		[self.color getHue:&h saturation:&s brightness:&v alpha:&alfa];
		NSorUIColor *cumulativeColor = [NSorUIColor colorWithHue:h saturation:s brightness:v*0.5 alpha:alfa];
#else
        NSorUIColor *cumulativeColor = [self.color shadowWithLevel:0.5];
#endif
		NSorUIBezierPath *cumulativePath = [NSorUIBezierPath bezierPath];
		oldX = (minX-minXaxis)*xPixelPerUnit;
		CGFloat oldCumulativeY = 0;
		newX = oldX;
		CGFloat newCumulativeY;
		[cumulativePath moveToPoint: NSorUIMakePoint(oldX, oldCumulativeY)];
		int i;
		for (i=minXindex; i<=maxXindex; i++) {
			newX = oldX + xPixelPerUnit*[self.modelObject binSize];
			CGFloat value = 0;
			if (i < maxXindex) value = [[self.modelObject valueForIndex:i] doubleValue];
			newCumulativeY = oldCumulativeY + value;
			[cumulativePath lineToPoint: NSorUIMakePoint(oldX, newCumulativeY*height)];
			[cumulativePath lineToPoint: NSorUIMakePoint(newX, newCumulativeY*height)];
			oldX = newX;
			oldCumulativeY = newCumulativeY;
		}
		[cumulativePath lineToPoint: NSorUIMakePoint(newX, height)];
        [cumulativeColor set];
        [cumulativePath stroke];

		// Draw the cumulative normal distribution for the given average and stddev
        double average = self.modelObject.average;
        double stddev = self.modelObject.stddev;
        double step = (maxXaxis - minXaxis) / dstRect.size.width;
		double cumvalue = 0;
#ifdef WITH_UIKIT
		[self.color getHue:&h saturation:&s brightness:&v alpha:&alfa];
		NSorUIColor *normalColor = [NSorUIColor colorWithHue:h saturation:s brightness:v*1.5 alpha:alfa];
#else
        NSorUIColor *normalColor = [self.color highlightWithLevel:0.5];
#endif
        path = [NSorUIBezierPath bezierPath];
        [path moveToPoint: NSorUIMakePoint(dstRect.origin.x, cumvalue * height)];
        for (int xindex=1; xindex <dstRect.size.width; xindex++) {
            double x = minXaxis + (xindex * step);
            //NSLog(@"%d normFunc(%f, %f, %f) = %f", xindex, x, average, stddev, normFunc(x, average, stddev));
            double value = normFunc(x+step/2, average, stddev);
			cumvalue = cumvalue + (value*step);
            //NSLog(@"(%f, %f)", x, y);
            [path lineToPoint: NSorUIMakePoint(dstRect.origin.x+xindex, cumvalue*height)];
        }
        [normalColor set];
        [path stroke];
		// And draw the average
		path = [NSorUIBezierPath bezierPath];
		double value = (average-minXaxis)*xPixelPerUnit;
		[path moveToPoint: NSorUIMakePoint(value, dstRect.origin.y)];
        [path lineToPoint: NSorUIMakePoint(value, dstRect.origin.y+dstRect.size.height) ];
        [cumulativeColor set];
        [path stroke];
		path = nil;
    }
#ifdef WITH_UIKIT
    CGContextRestoreGState(context);
#endif
    
}

@end
