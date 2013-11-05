#import "iSight.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <limits>

@implementation MyQTCaptureView
@synthesize delegate;

- (void)mouseDown: (NSEvent *)theEvent
{
	downPoint = [theEvent locationInWindow];
	NSLog(@"Mouse down (%d,%d)\n", (int)downPoint.x, (int)downPoint.y);
}

- (void)mouseUp: (NSEvent *)theEvent
{
	NSPoint upPoint = [theEvent locationInWindow];
	NSLog(@"Mouse up (%d,%d)\n", (int)upPoint.x, (int)upPoint.y);
	NSRect frame = [self frame];
	float top = frame.size.height - std::max(upPoint.y, downPoint.y);
	float height = abs(upPoint.y - downPoint.y);
	float left = std::min(upPoint.x, downPoint.x);
	float width = abs(upPoint.x - downPoint.x);
	NSRect r = {{left, top}, {width, height}};
	[[self delegate] focusRectSelected: r];
}

@end

@implementation iSight

- (void) awakeFromNib 
{    
	outputCapturer = nil;
    sampleBufferQueue = dispatch_queue_create("Sample Queue", DISPATCH_QUEUE_SERIAL);
    // Setup for callbacks 
    [selfView setDelegate: self];
    [[selfView window] setReleasedWhenClosed: false];

	NSLog(@"Devices: %@\n", [self deviceNames]);
	
	/* Select the default Video input device */
	AVCaptureDevice *dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	/* If we can't get a video device: get a muxed device */
	if (dev == NULL) {
		NSLog(@"Cannot find video device, will attempt multiplexed audio/video device\n");
		dev = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
	}
	if (dev == NULL) {
		NSLog(@"Cannot find any video device\n");
		NSRunAlertPanel(
			@"Warning",
			@"No suitable video input device found, reception disabled.", 
			nil, nil, nil);
		return;
	}
	
	[self switchToDevice: dev];
	
}

- (bool)available
{
	return session != nil && outputCapturer != nil;
}

- (NSArray*) deviceNames
{
	NSMutableArray *rv = [NSMutableArray arrayWithCapacity:128];
	/* First add the default Video input device */
	AVCaptureDevice *d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (d) [rv addObject: [d localizedName]]; 
	/* Next the default muxed device */
	d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
	if (d) [rv addObject: [d localizedName]];
	/* Next, all video devices */
	NSArray *devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
	for(d in devs) {
		NSString *name = [d localizedName];
		if ([rv indexOfObject: name] == NSNotFound)
			[rv addObject:name];
	}
	/* Finally, all muxed devices */
	devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeMuxed];
	for (d in devs) {
		NSString *name = [d localizedName];
		if ([rv indexOfObject: name] == NSNotFound)
			[rv addObject:name];
	}
	return rv;
}

- (void)switchToDeviceWithName: (NSString *)name
{
	AVCaptureDevice* dev = [self deviceWithName:name];
	[self switchToDevice:dev];
}

- (void)switchToDevice: (AVCaptureDevice*)dev
{
    // Delete old session, if needed
	if (outputCapturer) [outputCapturer release];
	outputCapturer = nil;
    if (selfLayer) [selfLayer removeFromSuperlayer];
	if (session) [session release];
	session = nil;
    
	//Create the AV capture session
	session = [[AVCaptureSession alloc] init];
    
	/* Create a QTKit input for the session using the iSight Device */
    NSError *error;
	AVCaptureDeviceInput *myInput = [AVCaptureDeviceInput deviceInputWithDevice:dev error:&error];
	if (error) {
        NSAlert *alert = [NSAlert alertWithError: error];
        [alert runModal];
        return;
    }
    /* Create the video capture output, set to greyscale, and let us be its delegate */
    outputCapturer = [[AVCaptureVideoDataOutput alloc] init];

    [outputCapturer setSampleBufferDelegate: self queue:sampleBufferQueue];
    
	/* Create a capture session for the live vidwo and add inputs get the ball rolling etc */
	[session addInput:myInput];
    if(selfView) {
        selfLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        selfLayer.frame = NSRectToCGRect(selfView.bounds);
        [selfView.layer addSublayer: selfLayer];
        [selfView setWantsLayer: YES];
    }
    [session addOutput: outputCapturer];
	
	/* Let the video madness begin */
	[session startRunning]; 
}

- (AVCaptureDevice*)deviceWithName: (NSString*)name
{
#if 1
	NSArray *devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
	AVCaptureDevice *d;
	for(d in devs) {
		NSString *dn = [d localizedName];
		if ([dn compare: name] == NSOrderedSame)
			return d;
	}
	devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeMuxed];
	for (d in devs) {
		NSString *dn = [d localizedName];
		if ([dn compare: name] == NSOrderedSame)
			return d;
	}
    return nil;
#else
	return [AVCaptureDevice deviceWithUniqueID:name];
#endif
}

#ifdef NOTYETFORAVFOUNDATION

- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image
{
	NSRect wbounds = [view previewBounds];
	CGRect ibounds = [image extent];
	xFactor = ibounds.size.width / wbounds.size.width;
	yFactor = ibounds.size.height / wbounds.size.height;

    // Noneed to process, show original image.
    return nil;
}
#endif
- (void)focusRectSelected: (NSRect)theRect
{
	theRect.origin.x *= xFactor;
	theRect.origin.y *= yFactor;
	theRect.size.width *= xFactor;
	theRect.size.height *= yFactor;
	NSLog(@"FocusRectSelected %d, %d, %d, %d\n", (int)theRect.origin.x, (int)theRect.origin.y, (int)theRect.size.width, (int)theRect.size.height);
	[manager setBlackWhiteRect: theRect];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
    fromConnection:(AVCaptureConnection *)connection;
{
	UInt64 now = CVGetCurrentHostTime();
    NSLog(@"Got video frame now=%lld pts=%f opts=%f dts=%f odts=%f\n", now,
          (float)CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)),
          (float)CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)),
          (float)CMTimeGetSeconds(CMSampleBufferGetDecodeTimeStamp(sampleBuffer)),
          (float)CMTimeGetSeconds(CMSampleBufferGetOutputDecodeTimeStamp(sampleBuffer)));
#if 0
    [manager newInputStart];
    OSType format = CVPixelBufferGetPixelFormatType(videoFrame);
	NSNumber *nHostTime = [sampleBuffer attributeForKey: QTSampleBufferHostTimeAttribute];
	UInt64 hostTime = [nHostTime longLongValue];
	double delta = (now-hostTime) / CVGetHostClockFrequency();
	[manager updateInputOverhead: delta];
//    NSLog(@"OStype %.4s 0x%x\n", &format, format);
    if (settings.running && settings.recv) {
		const char *formatStr;
		if (format == kCVPixelFormatType_32ARGB) {
			formatStr = "RGB4";
		} else if (format == kCVPixelFormatType_8IndexedGray_WhiteIsZero) {
			formatStr = "Y800";
        } else if (format == kCVPixelFormatType_422YpCbCr8) {
            formatStr = "UYVY";
        } else if (format == 'yuvs') {
            // Not in the Apple header files, but generated by iSight on my MacBook??
            formatStr = "YUYV";
		} else {
            // Unknown format??
            settings.recv = false;
            [settings updateButtonsIfNeeded];
            return;
        }
        CVPixelBufferLockBaseAddress(videoFrame, 0);
        void *buffer = CVPixelBufferGetBaseAddress(videoFrame);
        size_t w = CVPixelBufferGetWidth(videoFrame);
        size_t h = CVPixelBufferGetHeight(videoFrame);
        size_t size = CVPixelBufferGetDataSize(videoFrame);
//        assert (w==640);
//        assert (h==480);
//        assert (w==CVPixelBufferGetBytesPerRow(videoFrame));
        assert (size>=w*h);
        [manager newInputDone: buffer width: w height: h format: formatStr size:size];
        CVPixelBufferUnlockBaseAddress(videoFrame, 0);
    } else {
        [manager newInputDone];
    }
#endif
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
{
    // Should adjust maximal frame rate (minFrameDuration)
}
@end
