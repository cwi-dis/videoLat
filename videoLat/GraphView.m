//
//  GraphView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "GraphView.h"

@implementation GraphView

- (GraphView *)init
{
    self = [super init];
    source = nil;
    return self;
}

- (void)awakeFromNib
{
    myColor = [NSColor blueColor];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (source == nil || [source count] == 0) {
        NSLog(@"EMpty document for graph\n");
        return;
    }
    NSRect dstRect = [self bounds];
    CGFloat width = NSWidth(dstRect);
    CGFloat height = NSHeight(dstRect);
    
    // Determine X scale. Start at zero, unless we get less than a pixel per value,
    // then we discard the oldest data (lowest X indices)
    int minX = 0;
    int maxX = source.count-1;
    CGFloat xPixelPerUnit = (CGFloat)(maxX-minX) / width;
    if (xPixelPerUnit < 1.0) {
        // Don't show the left bit
        minX = (maxX - (int)width);
        xPixelPerUnit = 1;
    }
    
    // Determine Y scale. Go from 0 to at least max, but round up to 1/2/5 first digit.
    CGFloat minY = 0; // Not source.min;
    CGFloat maxY = source.max;

    maxY = 2*maxY; // XXXJACK
    CGFloat yPixelPerUnit = (maxY-maxX) / height;
    
    NSLog(@"%d < x < %d (scale=%f) %f < y < %f (scale=%f)\n", minX, maxX, xPixelPerUnit, minY, maxY, xPixelPerUnit);
    
    // Compute the closed path
    NSBezierPath *path = [NSBezierPath bezierPath];
    CGFloat oldX = minX, oldY = minY;
    CGFloat newX, newY;

    [path moveToPoint: NSMakePoint(oldX, oldY)];
    int i;
    for (i=minX; i<=maxX; i++) {
        newX = oldX + xPixelPerUnit;
        newY = [[source valueForIndex:i] doubleValue] * yPixelPerUnit;
        [path lineToPoint: NSMakePoint(oldX, newY)];
        [path lineToPoint: NSMakePoint(newX, newY)];
    }
    [path lineToPoint: NSMakePoint(newX, minY)];
    [path closePath];
    
    [myColor set];
    [path fill];
    [path stroke];
}

@end
