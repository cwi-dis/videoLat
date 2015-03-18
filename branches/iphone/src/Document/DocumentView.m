//
//  DocumentView.m
//  videoLat
//
//  Created by Jack Jansen on 12-11-13.
//
//

#import "DocumentView.h"
#import "AppDelegate.h"

@implementation DocumentView
@synthesize status;
@synthesize values;
@synthesize distribution;

- (Document *)modelObject { return _modelObject; }
- (void) setModelObject: (Document *)modelObject
{
    _modelObject = modelObject;
    [self _updateView];
}


- (DocumentView *)initWithFrame:(NSorUIRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        initialValues = NO;
#ifdef WITH_UIKIT
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        [self setMaxMinZoomScalesForCurrentBounds];
#endif
    }
    return self;
}

- (DocumentView *)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder: decoder];
    if (self) {
        initialValues = NO;
#ifdef WITH_UIKIT
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
        [self setMaxMinZoomScalesForCurrentBounds];
#endif
    }
    return self;
}

- (void) awakeFromNib
{
#ifdef WITH_UIKIT
    self.bouncesZoom = YES;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
#endif
}

#ifdef WITH_APPKIT
- (void)viewWillDraw
{
    if (!initialValues) {
        [self _updateView];
    }
    [super viewWillDraw];
}
#endif

- (void)_updateView
{
	if (self.modelObject && self.status && self.status.vInput && self.status.vOutput) {
        initialValues = YES;
		NSString *measurementType = self.modelObject.dataStore.measurementType;
        NSString *inputBaseMeasurementID = self.modelObject.dataStore.inputBaseMeasurementID;
        NSString *outputBaseMeasurementID = self.modelObject.dataStore.outputBaseMeasurementID;
		if (inputBaseMeasurementID && outputBaseMeasurementID && ![inputBaseMeasurementID isEqualToString: outputBaseMeasurementID]) {
			measurementType = [NSString stringWithFormat: @"%@ (based on %@ and %@)", measurementType, outputBaseMeasurementID, inputBaseMeasurementID];
        } else if (inputBaseMeasurementID) {
            measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, inputBaseMeasurementID];
            outputBaseMeasurementID = inputBaseMeasurementID;
        } else if (outputBaseMeasurementID) {
            measurementType = [NSString stringWithFormat: @"%@ (based on %@)", measurementType, outputBaseMeasurementID];
            inputBaseMeasurementID = outputBaseMeasurementID;
        }
		self.status.measurementType = measurementType;
        self.status.vInput.modelObject = self.modelObject.dataStore.input;
        self.status.vOutput.modelObject = self.modelObject.dataStore.output;
		self.status.date = self.modelObject.dataStore.date;
		self.status.description = self.modelObject.dataStore.description;
        if (_modelObject && _modelObject.dataStore) {
            self.status.detectCount = [NSString stringWithFormat: @"%d", self.modelObject.dataStore.count];
            self.status.missCount = [NSString stringWithFormat: @"%d", self.modelObject.dataStore.missCount];
            self.status.detectAverage = [NSString stringWithFormat: @"%.3f ms ± %.3f", self.modelObject.dataStore.average / 1000.0, self.modelObject.dataStore.stddev / 1000.0];
            self.status.detectMaxDelay = [NSString stringWithFormat:@"%.3f", self.modelObject.dataStore.max / 1000.0];
            self.status.detectMinDelay = [NSString stringWithFormat:@"%.3f", self.modelObject.dataStore.min / 1000.0];
            self.values.modelObject = self.modelObject.dataStore;
            self.values.xLabelFormat = @"%.0f";
            self.values.yLabelFormat = @"%.0f ms";
            self.values.showAverage = YES;
            self.values.yLabelScaleFactor = [NSNumber numberWithDouble:0.001];
            self.distribution.modelObject = self.modelObject.dataDistribution;
            self.distribution.showNormal = YES;
            self.distribution.xLabelFormat = @"%.0f ms";
            self.distribution.yLabelFormat = @"%0.f %%";
            self.distribution.yLabelScaleFactor = [NSNumber numberWithDouble: 100.0];
            self.distribution.xLabelScaleFactor = [NSNumber numberWithDouble:0.001];
            //self.distribution.maxYformat = @"%.2f";
        } else {
            self.status.detectCount = @"";
            self.status.detectAverage = @"";
            self.status.detectMaxDelay = @"";
            self.status.detectMinDelay = @"";
        }
	}
    [self.status update:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    // This is not very clean.....
#ifdef WITH_UIKIT
    self.status.description = self.status.bDescription.text;
#else
    self.status.description = self.status.bDescription.stringValue;
#endif
    self.modelObject.dataStore.description = self.status.description;
    [self.modelObject changed];
}

- (IBAction)openInputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSorUIApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.modelObject.dataStore.inputCalibration;
    if (d && s) {
#ifdef WITH_UIKIT_TEMP
		assert(0);
#else
        [d openUntitledDocumentWithMeasurement:s];
#endif
    }
}

- (IBAction)openOutputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSorUIApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.modelObject.dataStore.outputCalibration;
    if (d && s) {
#ifdef WITH_UIKIT_TEMP
		assert(0);
#else
        [d openUntitledDocumentWithMeasurement:s];
#endif
    }
}

#ifdef WITH_UIKIT
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.scrolledView;
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        //[self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        //[self recoverFromResizing];
        [self setMaxMinZoomScalesForCurrentBounds];
    }
}

#if 0
- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:_zoomView];
    
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:_zoomView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}
#endif

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGSize contentSize = self.scrolledView.frame.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / contentSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / contentSize.height;   // the scale needed to perfectly fit the image height-wise
    
    // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
    BOOL imagePortrait = contentSize.height > contentSize.width;
    BOOL phonePortrait = boundsSize.height > boundsSize.width;
    CGFloat minScale = imagePortrait == phonePortrait ? xScale : MIN(xScale, yScale);
    
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
    
    // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    self.maximumZoomScale = maxScale*2;
    self.minimumZoomScale = minScale;

    self.contentSize = contentSize;
    self.zoomScale = self.minimumZoomScale;
    
}

#endif
@end
