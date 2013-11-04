#import "iSight.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <limits>

@implementation MyQTCaptureView
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

    // Setup for callbacks 
    [selfView setDelegate: self];
    [[selfView window] setReleasedWhenClosed: false];

	NSLog(@"Devices: %@\n", [self deviceNames]);
	
	/* Select the default Video input device */
	QTCaptureDevice *dev = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	/* If we can't get a video device: get a muxed device */
	if (dev == NULL) {
		NSLog(@"Cannot find video device, will attempt multiplexed audio/video device\n");
		dev = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
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
	QTCaptureDevice *d = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
	if (d) [rv addObject: [d localizedDisplayName]]; 
	/* Next the default muxed device */
	d = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeMuxed];
	if (d) [rv addObject: [d localizedDisplayName]];
	/* Next, all video devices */
	NSArray *devs = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeVideo];
	for(d in devs) {
		NSString *name = [d localizedDisplayName];
		if ([rv indexOfObject: name] == NSNotFound)
			[rv addObject:name];
	}
	/* Finally, all muxed devices */
	devs = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeMuxed];
	for (d in devs) {
		NSString *name = [d localizedDisplayName];
		if ([rv indexOfObject: name] == NSNotFound)
			[rv addObject:name];
	}
	return rv;
}

- (void)switchToDeviceWithName: (NSString *)name
{
	QTCaptureDevice* dev = [self deviceWithName:name];
	[self switchToDevice:dev];
}

- (void)switchToDevice: (QTCaptureDevice*)dev
{
	if (outputCapturer) [outputCapturer release];
	outputCapturer = nil;
	if (session) [session release];
	session = nil;
	//Create the QT capture session
	session = [[QTCaptureSession alloc] init];
	/* Passing nil for the NSError parameter may not be the best idea
	 but i will leave error handling up to you */
	[dev open:nil];
    
	/* Create a QTKit input for the session using the iSight Device */
	QTCaptureDeviceInput *myInput = [QTCaptureDeviceInput deviceInputWithDevice:dev];
	
    /* Create the video capture output, set to greyscale, and let us be its delegate */
    outputCapturer = [[QTCaptureVideoPreviewOutput alloc] init];
#if 0
    // Code to ask for greyscale disabled, for two reasons:
    // - It breaks self-display on 64bit machines
    // - If we do the conversion ourselves (in findQRcodes) we can measure the overhead
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt: (int)kCVPixelFormatType_8IndexedGray_WhiteIsZero], kCVPixelBufferPixelFormatTypeKey,
        nil];
    [outputCapturer setPixelBufferAttributes:attrs];
#endif

    [outputCapturer setDelegate: self];
    
	/* Create a capture session for the live vidwo and add inputs get the ball rolling etc */
	[session addInput:myInput error:nil];
     if(selfView) [selfView setCaptureSession:session];
    [session addOutput: outputCapturer error:nil];
	
	/* Let the video madness begin */
	[session startRunning]; 
}

- (QTCaptureDevice*)deviceWithName: (NSString*)name
{
#if 1
	NSArray *devs = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeVideo];
	QTCaptureDevice *d;
	for(d in devs) {
		NSString *dn = [d localizedDisplayName];
		if ([dn compare: name] == NSOrderedSame)
			return d;
	}
	devs = [QTCaptureDevice inputDevicesWithMediaType: QTMediaTypeMuxed];
	for (d in devs) {
		NSString *dn = [d localizedDisplayName];
		if ([dn compare: name] == NSOrderedSame)
			return d;
	}
    return nil;
#else
	return [QTCaptureDevice deviceWithUniqueID:name];
#endif
}	

- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image
{
	NSRect wbounds = [view previewBounds];
	CGRect ibounds = [image extent];
	xFactor = ibounds.size.width / wbounds.size.width;
	yFactor = ibounds.size.height / wbounds.size.height;

    // Noneed to process, show original image.
    return nil;
}

- (void)focusRectSelected: (NSRect)theRect
{
	theRect.origin.x *= xFactor;
	theRect.origin.y *= yFactor;
	theRect.size.width *= xFactor;
	theRect.size.height *= yFactor;
	NSLog(@"FocusRectSelected %d, %d, %d, %d\n", (int)theRect.origin.x, (int)theRect.origin.y, (int)theRect.size.width, (int)theRect.size.height);
	[manager setBlackWhiteRect: theRect];
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput 
    didOutputVideoFrame:(CVImageBufferRef)videoFrame
    withSampleBuffer:(QTSampleBuffer *)sampleBuffer
    fromConnection:(QTCaptureConnection *)connection
{
	UInt64 now = CVGetCurrentHostTime();
    [manager newInputStart];
//    NSLog(@"Got video frame %lld %lld size %dx%d\n", 1000000LL*timestamp.timeValue / timestamp.timeScale, now_micro, (int)CVPixelBufferGetWidth(videoFrame), (int)CVPixelBufferGetHeight(videoFrame));
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
    
}

@end
