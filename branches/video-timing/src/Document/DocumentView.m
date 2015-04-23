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
	if (self.modelObject && self.modelObject.dataStore && self.status && self.status.vInput && self.status.vOutput) {
        initialValues = YES;
		self.status.modelObject = self.modelObject.dataStore;
        self.status.vInput.modelObject = self.modelObject.dataStore.input;
        self.status.vOutput.modelObject = self.modelObject.dataStore.output;
        if (_modelObject && _modelObject.dataStore) {
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
        }
	}
    [self.status update:self];
}

#ifdef WITH_APPKIT
- (IBAction)openInputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSorUIApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.modelObject.dataStore.inputCalibration;
    if (d && s) {
        [d openUntitledDocumentWithMeasurement:s];
    }
}

- (IBAction)openOutputCalibration:(id)sender
{
    AppDelegate *d = (AppDelegate *)[[NSorUIApplication sharedApplication] delegate];
    MeasurementDataStore *s = self.modelObject.dataStore.outputCalibration;
    if (d && s) {
        [d openUntitledDocumentWithMeasurement:s];
    }
}
#endif

#ifdef WITH_UIKIT
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.scrolledView;
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
        //[self setMaxMinZoomScalesForCurrentBounds];
    }
}

- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.scrolledView];
	if (_pointToCenterAfterResize.x < 0) _pointToCenterAfterResize.x = 0;
	if (_pointToCenterAfterResize.x > self.scrolledView.bounds.size.width) _pointToCenterAfterResize.x = self.scrolledView.bounds.size.width;
	if (_pointToCenterAfterResize.y < 0) _pointToCenterAfterResize.y = 0;
	if (_pointToCenterAfterResize.y > self.scrolledView.bounds.size.height) _pointToCenterAfterResize.y = self.scrolledView.bounds.size.height;

    _scaleToRestoreAfterResize = self.zoomScale;

}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
	CGFloat bestZoomScale = MIN(self.maximumZoomScale/4, maxZoomScale);
    self.zoomScale = bestZoomScale;
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:self.scrolledView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    self.contentOffset = offset;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.bounds.size;
    CGSize contentSize = self.scrolledView.bounds.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / contentSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / contentSize.height;   // the scale needed to perfectly fit the image height-wise
    
    // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
	CGFloat minScale = MIN(xScale, yScale);
    CGFloat maxScale = MAX(xScale, yScale);
    self.maximumZoomScale = maxScale*4;
    self.minimumZoomScale = minScale;

    self.contentSize = contentSize;
}

- (NSData *)generatePDF
{
   NSMutableData * pdfData=[NSMutableData data];

   CGRect viewRect = self.scrolledView.bounds;
   CGRect pageRect = CGRectMake(0, 0, 612, 792);
   CGFloat xScale = pageRect.size.width / viewRect.size.width;
   CGFloat yScale = pageRect.size.height / viewRect.size.height;

   UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil);
   UIGraphicsBeginPDFPage();
   CGContextRef pdfContext = UIGraphicsGetCurrentContext();
   CGContextScaleCTM(pdfContext, MIN(xScale, yScale), MIN(xScale, yScale));
   CGContextTranslateCTM(pdfContext, 30, 0);
   [self.scrolledView.layer renderInContext:pdfContext];
   UIGraphicsEndPDFContext();
 
   // and return the PDF data.
   return pdfData;

}
#endif
@end
