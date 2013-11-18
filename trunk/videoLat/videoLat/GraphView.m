//
//  GraphView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "GraphView.h"

static double _RoundTo125(double value)
{
    double magnitude;
    magnitude = floor(log10(value));
    value /= pow(10.0, magnitude);
    if (value < 1.5)
        value = 1.0;
    else if (value < 3.5)
        value = 2.0;
    else if (value < 7.5)
        value = 5.0;
    else
        value = 10.0;
    value *= pow(10.0, magnitude);
    return value;
}

@implementation GraphView

- (GraphView *)init
{
    self = [super init];
    return self;
}

- (void)awakeFromNib
{
    myColor = [NSColor blueColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.source == nil || [self.source count] == 0) {
        NSLog(@"EMpty document for graph\n");
        return;
    }
    NSRect dstRect = [self bounds];
    CGFloat width = NSWidth(dstRect);
    CGFloat height = NSHeight(dstRect);
    
    // Determine X scale. Start at zero, unless we get less than a pixel per value,
    // then we discard the oldest data (lowest X indices)
    int minX = 0;
    int maxX = self.source.count-1;
    CGFloat maxXaxis = (CGFloat)_RoundTo125(maxX);
    CGFloat xPixelPerUnit = width / (CGFloat)(maxXaxis-minX);
    if (xPixelPerUnit < 1.0) {
        // Don't show the left bit
        minX = (maxX - (int)width);
        maxXaxis = maxX;
        xPixelPerUnit = 1;
    }
    if (minX < 0) minX = 0;
    
    // Determine Y scale. Go from 0 to at least max, but round up to 1/2/5 first digit.
    CGFloat minY = 0; // Not source.min;
    CGFloat maxY = self.source.max;
    CGFloat maxYaxis = (CGFloat)_RoundTo125(maxY);

    CGFloat yPixelPerUnit = (maxYaxis-minY) / height;
    if (yPixelPerUnit == 0) yPixelPerUnit = 1;

	if (self.bMaxX) self.bMaxX.stringValue = [NSString stringWithFormat:@"%f", maxXaxis];
	if (self.bMaxY) self.bMaxY.stringValue = [NSString stringWithFormat:@"%f", maxYaxis];

    NSLog(@"%d < x < %d (scale=%f, axis=%f) %f < y < %f (scale=%f, axis=%f)\n", minX, maxX, xPixelPerUnit, maxXaxis, minY, maxY, yPixelPerUnit, maxYaxis);
    
    // Compute the closed path
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGFloat oldX = minX, oldY = minY;
    CGFloat newX, newY;

    [path moveToPoint: NSMakePoint(oldX, oldY)];
    int i;
    for (i=minX; i<=maxX; i++) {
        newX = oldX + xPixelPerUnit;
        newY = [[self.source valueForIndex:i] doubleValue] / yPixelPerUnit;
        [path lineToPoint: NSMakePoint(oldX, newY)];
        [path lineToPoint: NSMakePoint(newX, newY)];
        NSLog(@"point %f, %f", newX, newY);
        oldX = newX;
        oldY = newY;
    }
    [path lineToPoint: NSMakePoint(newX, minY)];
    [path closePath];
    
    [myColor set];
    [path fill];
    [path stroke];
}

@end
