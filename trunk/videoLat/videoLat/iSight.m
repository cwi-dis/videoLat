#import "iSight.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>

@implementation MyQTCaptureView
@synthesize delegate;
@synthesize visibleButton;

- (IBAction)visibleChanged: (id) sender
{
    [self setHidden: ([sender state] == NSOffState)];
}

- (void)setHidden: (BOOL) onOff
{
    if (onOff)
        [visibleButton setState:NSOffState];
    else
        [visibleButton setState:NSOnState];
    [super setHidden: onOff];
}

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
    float max_y = upPoint.y;
    if (downPoint.y > max_y) max_y = downPoint.y;
	float top = frame.size.height - max_y;
	float height = abs(upPoint.y - downPoint.y);
	float left = upPoint.x;
    if (downPoint.x < left) left = downPoint.x;
	float width = abs(upPoint.x - downPoint.x);
	NSRect r = {{left, top}, {width, height}};
	[[self delegate] focusRectSelected: r];
}

@end

@implementation iSight
@synthesize deviceID;
@synthesize deviceName;

- (iSight *)init
{
    self = [super init];
    if (self) {
        outputCapturer = nil;
        deviceID = nil;
        sampleBufferQueue = dispatch_queue_create("Sample Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) awakeFromNib
{    
    // Setup for callbacks
    [selfView setDelegate: self];
// XYZZY    [[selfView window] setReleasedWhenClosed: false];

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
	
	[self _switchToDevice: dev];
	
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

- (BOOL)switchToDeviceWithName: (NSString *)name
{
	AVCaptureDevice* dev = [self _deviceWithName:name];
    if (dev == nil)
        return NO;
	[self _switchToDevice:dev];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"Camera"];
    return YES;
}

- (void)_switchToDevice: (AVCaptureDevice*)dev
{
	deviceID = [dev modelID];
	deviceName = [dev localizedName];
    // Delete old session, if needed
	outputCapturer = nil;
    if (selfLayer) [selfLayer removeFromSuperlayer];
	if (session) {
        [session stopRunning];
    }
	session = nil;
    
	//Create the AV capture session
	session = [[AVCaptureSession alloc] init];
    
#if 0
    // This code not enabled yet, because I don't have a camera that supports it:-)
    
    // Set focus/exposure/flash, if device supports it
    if ([dev isFocusPointOfInterestSupported] && [dev isFocusModeSupported:AVCaptureFocusModeLocked] ) {
        NSLog(@"Device supports focus lock\n");
    }
    if ([dev isTorchModeSupported: AVCaptureTorchModeOff]) {
        NSLog(@"Device supports torch-off\n");
        dev.torchMode = AVCaptureTorchModeOff;
    }
    if ([dev isExposurePointOfInterestSupported] && [dev isExposureModeSupported:AVCaptureExposureModeLocked] ) {
        NSLog(@"Device supports exposure lock\n");
    }
    NSLog(@"Finished looking at device capabilities\n");
#endif
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
    if ([session canSetSessionPreset: AVCaptureSessionPreset640x480]) {
        [session setSessionPreset: AVCaptureSessionPreset640x480];
    } else {
        NSLog(@"Warning: Cannot set capture session to 640x480\n");
    }
    if(selfView) {
        selfLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
        selfLayer.frame = NSRectToCGRect(selfView.bounds);
        [selfView setWantsLayer: YES];
        [selfView.layer addSublayer: selfLayer];
        [selfView setHidden: NO];
    }
    [session addOutput: outputCapturer];
	// XXXJACK Should catch AVCaptureSessionRuntimeErrorNotification
    
	/* Let the video madness begin */
	[session startRunning]; 
}

- (AVCaptureDevice*)_deviceWithName: (NSString*)name
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

- (void) startCapturing
{
#if 0
    // Lock focus and exposure, if supported
#endif
    // Hide preview
    [selfView setHidden: YES];
}

- (void) stopCapturing
{
    [selfView setHidden: NO];
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
	[manager setFinderRect: theRect];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
    fromConnection:(AVCaptureConnection *)connection;
{
	UInt64 now = CVGetCurrentHostTime();
    if( !CMSampleBufferDataIsReady(sampleBuffer) )
    {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    CMTime timestampCMT = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    timestampCMT = CMTimeConvertScale(timestampCMT, 1000000000, kCMTimeRoundingMethod_Default);
    UInt64 timestamp = timestampCMT.value;
	if (timestamp > now) {
		NSLog(@"iSight: dropping frame with timestamp %lld which is %lldns in the future", timestamp, timestamp-now);
		return;
	}
    [manager newInputStart];
#if 0
	double delta = (now-timestamp) / CVGetHostClockFrequency();
	[manager updateInputOverhead: delta];
#endif
    // NSLog(@"Got video frame from %p now=%lld pts=%lld delta=%f\n", (void*)connection, now, timestamp, delta);
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    OSType format = CMFormatDescriptionGetMediaSubType(formatDescription);
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //NSLog(@"OStype %.4s 0x%x\n", &format, format);
	const char *formatStr;
	if (format == kCVPixelFormatType_32ARGB) {
		formatStr = "RGB4";
	} else if (format == kCVPixelFormatType_8IndexedGray_WhiteIsZero) {
		formatStr = "Y800";
	} else if (format == kCVPixelFormatType_422YpCbCr8) {
		formatStr = "UYVY";
	} else if (format == 'yuvs' || format == 'yuv2') {
		// Not in the Apple header files, but generated by iSight on my MacBook??
		formatStr = "YUYV";
	} else {
		// Unknown format??
		formatStr = "unknown";
	}
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void *buffer = CVPixelBufferGetBaseAddress(pixelBuffer);
	size_t w = CVPixelBufferGetWidth(pixelBuffer);
	size_t h = CVPixelBufferGetHeight(pixelBuffer);
	size_t size = CVPixelBufferGetDataSize(pixelBuffer);
	assert (size>=w*h);
	[manager newInputDone: buffer width: (int)w height: (int)h format: formatStr size:(int)size];
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
{
    // Should adjust maximal frame rate (minFrameDuration)
    NSLog(@"camera capturer dropped frame...\n");
}
@end
