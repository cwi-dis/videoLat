#import "VideoInput.h"
#import "EventLogger.h"
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>
#import <mach/mach_time.h>
#import <mach/clock.h>

@implementation VideoInputView
@synthesize delegate;
@synthesize visibleButton;


#ifdef WITH_UIKIT
- (void)layoutSubviews
{
	CALayer *selfLayer = self.layer;
    if(self.layer && self.layer.sublayers && [self.layer.sublayers count] == 1) {
        CALayer *videoLayer = [self.layer.sublayers objectAtIndex:0];
        videoLayer.frame = selfLayer.bounds;
    }

}
#else
- (IBAction)visibleChanged: (id) sender
{
    [self setHidden: ([sender state] == NSOffState)];
}

- (void)dealloc
{
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
    downPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (1 || VL_DEBUG) NSLog(@"Mouse down (%d,%d)\n", (int)downPoint.x, (int)downPoint.y);
}

- (void)mouseUp: (NSEvent *)theEvent
{
	NSPoint upPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (1 || VL_DEBUG) NSLog(@"Mouse up (%d,%d)\n", (int)upPoint.x, (int)upPoint.y);
	NSRect frame = [self frame];

    float left = MIN(downPoint.x, upPoint.x);
    float right = MAX(downPoint.x, upPoint.x);
    float top = MAX(downPoint.y, upPoint.y);
    float bottom = MIN(downPoint.y, upPoint.y);
    float width = right - left;
    float height = top - bottom;

    NSRect r = {{left/frame.size.width, bottom/frame.size.height}, {width/frame.size.width, height/frame.size.height}};
	[[self delegate] focusRectSelected: r];
}
#endif
@end

@implementation VideoInput
@synthesize deviceID;
@synthesize deviceName;

+ (NSArray *) allDeviceTypeIDs
{
    NSMutableArray *rv = [NSMutableArray arrayWithCapacity:128];;
    AVCaptureDevice *d;
    NSArray *devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
    for(d in devs) {
        NSString *name = [d modelID];
        if ([rv indexOfObject: name] == NSNotFound)
            [rv addObject:name];
    }
    /* next, all muxed devices */
    devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeMuxed];
    for (d in devs) {
        NSString *name = [d localizedName];
        if ([rv indexOfObject: name] == NSNotFound)
            [rv addObject:name];
    }
    return rv;
}

- (VideoInput *)init
{
    self = [super init];
    if (self) {
        outputCapturer = nil;
        deviceID = nil;
        sampleBufferQueue = dispatch_queue_create("Video Sample Queue", DISPATCH_QUEUE_SERIAL);
#ifdef notWITH_DEVICE_CLOCK
		if (CMClockGetHostTimeClock != NULL) {
			clock = CMClockGetHostTimeClock();
		}
#endif
#ifdef WITH_ADJUST_CLOCK_DRIFT
        epoch = [self now];
#else
        epoch = 0;
#endif
#ifdef WITH_STATISTICS
		firstTimeStamp = 0;
		lastTimeStamp = 0;
		nFrames = 0;
		nFramesDropped = 0;
#endif
    }
    return self;
}

- (void)dealloc
{
	[self stop];
}

- (void) awakeFromNib
{    
    [super awakeFromNib];
    
    // Setup for callbacks
    [self.selfView setDelegate: self];

	if (VL_DEBUG) NSLog(@"Devices: %@\n", [self deviceNames]);
}

- (uint64_t)now
{
    UInt64 timestamp;
#ifdef WITH_DEVICE_CLOCK
    if (clock) {
        CMTime timestampCMT = CMClockGetTime(clock);
        timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
        timestamp = timestampCMT.value;
    } else
#endif
	{
		timestamp = monotonicMicroSecondClock();
    }
    return timestamp - epoch;
}

- (void) stop
{
	outputCapturer = nil;
    if (selfLayer) [selfLayer removeFromSuperlayer];
	selfLayer = nil;
	if (session) {
        [session stopRunning];
    }
	session = nil;
    //dispatch_release(sampleBufferQueue);
    sampleBufferQueue = nil;
#ifdef WITH_DEVICE_CLOCK
	clock = nil;
#endif
#ifdef WITH_STATISTICS
	float deltaT = (lastTimeStamp-firstTimeStamp) / 1000000.0;
	NSLog(@"Captured %.1f seconds, %d frames, %3.1f fps capture,  %d drops, %3.1f fps captured+dropped",
		deltaT, nFrames, nFrames/deltaT, nFramesDropped, (nFrames+nFramesDropped)/deltaT);
    firstTimeStamp = 0;
    lastTimeStamp = 0;
    nFrames = 0;
    nFramesDropped = 0;
#endif
}

- (bool)available
{
	return session != nil && outputCapturer != nil;
}

+ (NSArray*) deviceNames
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
	if ([rv count] == 0) {
		showWarningAlert(@"No suitable video input device found, reception disabled.");
	}
	return rv;
}

- (NSArray *)deviceNames
{
	return [[self class] deviceNames];
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
    if (VL_DEBUG) NSLog(@"Switching to device %@\n", name);
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
    
    // This code not enabled yet, because I don't have a camera that supports it:-)
    if ([dev lockForConfiguration: nil]) {
        // Set focus/exposure/flash, if device supports it
        if ([dev isFocusPointOfInterestSupported] && [dev isFocusModeSupported:AVCaptureFocusModeLocked] ) {
            if (VL_DEBUG) NSLog(@"Device supports focus lock\n");
        }
        if ([dev isTorchModeSupported: AVCaptureTorchModeOff]) {
            if (VL_DEBUG) NSLog(@"Device supports torch-off\n");
            dev.torchMode = AVCaptureTorchModeOff;
        }
        if ([dev isExposurePointOfInterestSupported] && [dev isExposureModeSupported:AVCaptureExposureModeLocked] ) {
            if (VL_DEBUG) NSLog(@"Device supports exposure lock\n");
        }
		// XXXJACK set max frame duration
		NSArray *supportedFrameRates = dev.activeFormat.videoSupportedFrameRateRanges;
		AVFrameRateRange *activeRange = [supportedFrameRates objectAtIndex:0];
        CMTime minDuration = activeRange.minFrameDuration;
		dev.activeVideoMinFrameDuration = minDuration;

		[dev unlockForConfiguration];
    }
    if (VL_DEBUG) NSLog(@"Finished looking at device capabilities\n");
	/* Create a QTKit input for the session using the iSight Device */
    NSError *error;
	AVCaptureDeviceInput *myInput = [AVCaptureDeviceInput deviceInputWithDevice:dev error:&error];
	if (error) {
        showErrorAlert(error);
        return;
    }
    
	/* Create a capture session for the live vidwo and add inputs get the ball rolling etc */
	[session addInput:myInput];
    if ([session canSetSessionPreset: AVCaptureSessionPreset640x480]) {
        [session setSessionPreset: AVCaptureSessionPreset640x480];
    } else {
        NSLog(@"Warning: Cannot set capture session to 640x480\n");
    }
#ifdef WITH_DEVICE_CLOCK
    // Try and find the video input
    AVCaptureInputPort *videoPort = nil;
    for (AVCaptureInputPort *p in myInput.ports) {
        if ([p.mediaType isEqualToString: AVMediaTypeVideo]) {
            if (videoPort) {
                NSLog(@"Warning: device has multiple video input ports, assuming first one");
            } else {
                videoPort = p;
            }
        }
    }
    if (videoPort == nil) {
        NSLog(@"Warning: device has no video input ports (?)");
    } else {
        // Attempt to use the clock for this input port as our master clock
        if ( [videoPort respondsToSelector:@selector(clock)]) {
            CMClockRef devClock = [videoPort clock];
            if (devClock) {
                NSLog(@"Using device clock %@", devClock);
                uint64_t oldNow = [self now];
                clock = devClock;
                epoch = 0;
                uint64_t newNow = [self now];
                epoch = newNow - oldNow;
            } else {
                NSLog(@"Warning: video device has no clock");
            }
        }
    }
#endif
    /* Create the video capture output, and let us be its delegate */
    outputCapturer = [[AVCaptureVideoDataOutput alloc] init];
	outputCapturer.alwaysDiscardsLateVideoFrames = YES;
    [outputCapturer setSampleBufferDelegate: self queue:sampleBufferQueue];
    [session addOutput: outputCapturer];
	// XXXJACK Should catch AVCaptureSessionRuntimeErrorNotification

    if(self.selfView) {
        CALayer* videoLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
#ifdef WITH_UIKIT
		CGRect bounds = self.selfView.bounds;
		videoLayer.frame = bounds;
        overlayLayer = nil;
        selfLayer = videoLayer;
#else
        overlayLayer = [CALayer layer];
        overlayLayer.delegate = self;
        CALayer* parentLayer = [CALayer layer];
        [parentLayer addSublayer: videoLayer];
        [parentLayer addSublayer: overlayLayer];
        overlayLayer.opacity = 0.8;
        videoLayer.frame = NSRectToCGRect(self.selfView.bounds);
        overlayLayer.frame = NSRectToCGRect(self.selfView.bounds);
        parentLayer.frame = NSRectToCGRect(self.selfView.bounds);
        [self.selfView setWantsLayer: YES];
        selfLayer = parentLayer;
#endif
        [self.selfView.layer addSublayer: selfLayer];
        [overlayLayer setNeedsDisplay];
        [self.selfView setHidden: NO];
    }
    
	if (1 || VL_DEBUG) NSLog(@"Camera format: %@ %@ %@", dev.activeFormat.mediaType, dev.activeFormat.formatDescription, dev.activeFormat.videoSupportedFrameRateRanges);

	/* Let the video madness begin */
	capturing = NO;
#ifdef WITH_STATISTICS
	firstTimeStamp = 0;
	lastTimeStamp = 0;
	nFrames = 0;
	nFramesDropped = 0;
#endif
	[self.manager restart];
	VL_LOG_EVENT(@"startCamera", 0, deviceName);
	[session startRunning];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
    float width = layer.frame.size.width;
    float height = layer.frame.size.height;
    for(NSValue *rectVal in self.overlayRects) {
#ifdef WITH_APPKIT
        NSRect rect = rectVal.rectValue;
#else
        CGRect rect = rectVal.CGRectValue;
#endif
        rect.origin.x *= width;
        rect.origin.y *= height;
        rect.size.width *= width;
        rect.size.height *= height;
        CGContextStrokeRect(context, rect);
    }
}

- (void)setMinCaptureInterval: (uint64_t)interval
{
#ifdef WITH_SET_MIN_CAPTURE_DURATION
    assert(session.inputs.count == 1);
    AVCaptureDeviceInput *input = session.inputs[0];
    assert(input);
    AVCaptureDevice *device = input.device;
    assert(device);
    if ([device lockForConfiguration: nil]) {
        // Set focus/exposure/flash, if device supports it
        NSArray *supportedFrameRates = device.activeFormat.videoSupportedFrameRateRanges;
        AVFrameRateRange *activeRange = [supportedFrameRates objectAtIndex:0];
        CMTime minDuration = activeRange.minFrameDuration;
        CMTime maxDuration = activeRange.maxFrameDuration;
        
        CMTime wantedDuration = CMTimeMake(interval, 1000000);
        wantedDuration = CMTimeMinimum(wantedDuration, maxDuration);
        wantedDuration = CMTimeMaximum(wantedDuration, minDuration);
        device.activeVideoMinFrameDuration = wantedDuration;
        
        [device unlockForConfiguration];
#ifdef WITH_STATISTICS
		firstTimeStamp = 0;
		lastTimeStamp = 0;
		nFrames = 0;
		nFramesDropped = 0;
#endif
    } else {
        NSLog(@"VideoInput: cannot lock video input device to set frame duration");
    }
#endif
}

- (void)pauseCapturing: (BOOL) pause
{
	if (session == nil) return;
	if (pause) {
		if (session.running)
			[session stopRunning];
		session = nil;
	} else {
		if (!session.running)
			[session startRunning];
	}
}

- (AVCaptureDevice*)_deviceWithName: (NSString*)name
{
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
}

- (void) startCapturing: (BOOL) showPreview
{
    // Hide preview
    if (!showPreview) [self.selfView setHidden: YES];
	capturing = YES;
}

- (void) stopCapturing
{
    [self.selfView setHidden: NO];
	capturing = NO;
}

- (void)focusRectSelected: (NSorUIRect)theRect
{
    // Show to the user
#ifdef WITH_APPKIT
    self.overlayRects = [NSArray arrayWithObject:[NSValue valueWithRect:theRect]];
#else
    self.overlayRects = [NSArray arrayWithObject:[NSValue valueWithCGRect:theRect]];
#endif
    [overlayLayer setNeedsDisplay];
    
	theRect.origin.x *= xFactor;
	theRect.origin.y *= yFactor;
	theRect.size.width *= xFactor;
	theRect.size.height *= yFactor;
	if (VL_DEBUG) NSLog(@"FocusRectSelected %d, %d, %d, %d\n", (int)theRect.origin.x, (int)theRect.origin.y, (int)theRect.size.width, (int)theRect.size.height);
	[self.manager setFinderRect: theRect];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
    fromConnection:(AVCaptureConnection *)connection;
{
    if( !CMSampleBufferDataIsReady(sampleBuffer) )
    {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    CMTime timestampCMT = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
    UInt64 timestamp = timestampCMT.value;
    UInt64 now_timestamp = [self now];
    SInt64 delta = now_timestamp - timestamp;
	VL_LOG_EVENT(@"cameraCaptureVideoClock", timestamp, @"");
	VL_LOG_EVENT(@"cameraCaptureSelfClock", now_timestamp, ([NSString stringWithFormat:@"delta=%lld", delta]));
    if (!capturing) {
        // We are not yet capturing, we optionally adjust the clock and return.
#ifdef WITH_ADJUST_CLOCK_DRIFT
        if (delta <= -WITH_ADJUST_CLOCK_DRIFT || delta >= WITH_ADJUST_CLOCK_DRIFT) {
            //
            // Suspect code ahead. On some combinations of camera and OS the video presentation
            // timestamp clock drifts. We compensate by slowly moving the epoch of our software
            // clock (which is used for output timestamping) to move towards the video input
            // timestamp clock. We do so slowly, because our dispatch_queue seems to give us
            // callbacks in some time-slotted fashion.
            epoch += (delta/WITH_ADJUST_CLOCK_DRIFT_FACTOR);
            NSLog(@"VideoInput: clock: delta %lld us, epoch set to %lld uS", delta, epoch);
            VL_LOG_EVENT(@"adjustedClock",[self now], ([NSString stringWithFormat:@"delta=%lld,adjust=%lld", delta, delta/WITH_ADJUST_CLOCK_DRIFT_FACTOR]));
        }
#else
        if (delta < 0) {
            // The capture time of this frame cannot ever be before now. So we adjust the epoch.
            NSLog(@"VideoInput: clock: delta %lld us, adjusting epoch", delta);
            epoch += delta;
        }
#endif
        if (xFactor == 0 || yFactor == 0) {
            CVImageBufferRef tmpBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            size_t w = CVPixelBufferGetWidth(tmpBuffer);
            size_t h = CVPixelBufferGetHeight(tmpBuffer);
            xFactor = w;
            yFactor = h;
        }
#ifdef WITH_STATISTICS
        firstTimeStamp = 0;
        lastTimeStamp = 0;
        nFrames = 0;
        nFramesDropped = 0;
#endif
        return;
    }
#ifdef WITH_STATISTICS
    if (firstTimeStamp == 0) firstTimeStamp = timestamp;
    lastTimeStamp = timestamp;
    nFrames++;
#endif

    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
#if 1
    [self.manager newInputDone: pixelBuffer at: now_timestamp];
#else
    // It would theoretically be better to use the real camera timestamp but
    // unfortunately this invalidates all old calibrations....
    [self.manager newInputDone: pixelBuffer at: timestamp];
#endif
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection;
{
	VL_LOG_EVENT(@"cameraCaptureDrop", 0, @"");
	nFramesDropped++;
    // Should adjust maximal frame rate (minFrameDuration)
    if (VL_DEBUG) NSLog(@"camera capturer dropped frame...\n");
}
@end
