//
//  AudioInput.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioInput.h"
#import <mach/clock.h>


@implementation AudioInput

@synthesize deviceID;
@synthesize deviceName;
@synthesize manager;

- (AudioInput *)init
{
    self = [super init];
    if (self) {
        outputCapturer = nil;
        deviceID = nil;
        sampleBufferQueue = dispatch_queue_create("Audio Sample Queue", DISPATCH_QUEUE_SERIAL);
#if TARGET_OS_IPHONE || (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1080)
		if (CMClockGetHostTimeClock != NULL) {
			clock = CMClockGetHostTimeClock();
		}
#endif
        epoch = 0;
    }
    return self;
}

- (void)dealloc
{
	[self stop];
}

- (uint64_t)now
{
    UInt64 timestamp;
#if TARGET_OS_IPHONE || (0 && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080)
    if (clock) {
        CMTime timestampCMT = CMClockGetTime(clock);
        timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
        timestamp = timestampCMT.value;
    } else
#endif
	{
#if TARGET_OS_IPHONE
        assert(0);
#else
		clock_serv_t cclock;
		mach_timespec_t mts;
        
		host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
		clock_get_time(cclock, &mts);
		mach_port_deallocate(mach_task_self(), cclock);
		timestamp = ((UInt64)mts.tv_sec*1000000LL) + mts.tv_nsec/1000LL;
#endif
    }
    return timestamp - epoch;
}

- (void) stop
{
	outputCapturer = nil;
	if (session) {
        [session stopRunning];
    }
	session = nil;
    sampleBufferQueue = nil;
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080
	clock = nil;
#endif
}


- (bool)available
{
	return session != nil && outputCapturer != nil;
}

- (NSArray*) deviceNames
{
	NSMutableArray *rv = [NSMutableArray arrayWithCapacity:128];
	/* First add the default audio input device */
	AVCaptureDevice *d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	if (d) [rv addObject: [d localizedName]];
	/* Next the default muxed device */
	d = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
	if (d) [rv addObject: [d localizedName]];
	/* Next, all audio devices */
	NSArray *devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeAudio];
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
        showWarningAlert(@"No suitable audio input device found, reception disabled.");
	}
	return rv;
}

- (BOOL)switchToDeviceWithName: (NSString *)name
{
    if (1 || VL_DEBUG) NSLog(@"Switching to device %@\n", name);
	if (name == nil) return NO;
	AVCaptureDevice* dev = [self _deviceWithName:name];
    if (dev == nil)
        return NO;
	[self _switchToDevice:dev];
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"AudioInput"];
    return YES;
}

- (void)_switchToDevice: (AVCaptureDevice*)dev
{
	deviceID = [dev modelID];
	deviceName = [dev localizedName];
    // Delete old session, if needed
	outputCapturer = nil;
	if (session) {
        [session stopRunning];
    }
	session = nil;
    
	//Create the AV capture session
	session = [[AVCaptureSession alloc] init];
    
    // This code not enabled yet, because I don't have a camera that supports it:-)
    if ([dev lockForConfiguration: nil]) {
        
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
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090
    // Try and find the audio input
    AVCaptureInputPort *audioPort = nil;
    for (AVCaptureInputPort *p in myInput.ports) {
        if ([p.mediaType isEqualToString: AVMediaTypeAudio]) {
            if (audioPort) {
                NSLog(@"Warning: device has multiple audio input ports, assuming first one");
            } else {
                audioPort = p;
            }
        }
    }
    if (audioPort == nil) {
        NSLog(@"Warning: device has no audio input ports (?)");
    } else {
        // Attempt to use the clock for this input port as our master clock
        if ( [audioPort respondsToSelector:@selector(clock)]) {
            CMClockRef devClock = [audioPort clock];
            if (devClock) {
                NSLog(@"Using device clock %@", devClock);
                clock = devClock;
                epoch = 0;
            }
        }
    }
#endif
    /* Create the audio capture output, and let us be its delegate */
    outputCapturer = [[AVCaptureAudioDataOutput alloc] init];
    [outputCapturer setSampleBufferDelegate: self queue:sampleBufferQueue];
    [session addOutput: outputCapturer];
#if !TARGET_OS_IPHONE
    if ([outputCapturer respondsToSelector:@selector(audioSettings)]) {
        // Not available on iOS. We chance it.
        // XXXJACK Should catch AVCaptureSessionRuntimeErrorNotification
        // Set the parameters so that we get the samples in a format we understand.
        // Unfortunately, setting to 'mono' doesn't seem to work, at least not consistently...
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
            [NSNumber numberWithFloat:44100], AVSampleRateKey,
    //		[NSNumber numberWithUnsignedInteger:1], AVNumberOfChannelsKey,
            [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
            [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
    //		[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
            nil];
        [outputCapturer setAudioSettings: settings];
    }
#endif
    /* Let the madness begin */
	capturing = NO;
	epoch = 0;
	[self.manager restart];
	[session startRunning];
}

- (void)pauseCapturing: (BOOL) pause
{
	if (session == nil) return;
	if (pause) {
		if (session.running)
			[session stopRunning];
	} else {
		if (!session.running)
			[session startRunning];
	}
}

- (AVCaptureDevice*)_deviceWithName: (NSString*)name
{
#if 1
	NSArray *devs = [AVCaptureDevice devicesWithMediaType: AVMediaTypeAudio];
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

- (void) startCapturing: (BOOL) showPreview
{
    capturing = YES;
}

- (void) stopCapturing
{
    capturing = NO;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // Determine input level for VU-meter
    float db = 0;
    AVCaptureConnection *conn = [outputCapturer.connections objectAtIndex: 0];
    AVCaptureAudioChannel *ch;
    for (ch in conn.audioChannels) {
        db += ch.averagePowerLevel;
    }
    db /= [connection.audioChannels count];
    float level = (pow(10.f, 0.05f * db) * 20.0f);
	if (VL_DEBUG) NSLog(@"Input level=%f", level);
#ifdef WITH_UIKIT
	dispatch_async(dispatch_get_main_queue(), ^{
        [self.bInputValue setProgress: level];
    });

#else
    [self.bInputValue setFloatValue:level*100];
#endif

	// Get the audio data and timestamp
	
    if( !CMSampleBufferDataIsReady(sampleBuffer) )
    {
        NSLog( @"sample buffer is not ready. Skipping sample" );
        return;
    }
    if( CMSampleBufferMakeDataReady(sampleBuffer) != noErr)
    {
        NSLog( @"Cannot make data ready. Skipping sample" );
        return;
    }
    CMTime timestampCMT = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
    UInt64 timestamp = timestampCMT.value;
    UInt64 now_timestamp = [self now];
    SInt64 delta = now_timestamp - timestamp;
    if (1) {
        //
        // Suspect code ahead. On some combinations of camera and OS the video presentation
        // timestamp clock drifts. We compensate by slowly moving the epoch of our software
        // clock (which is used for output timestamping) to move towards the video input
        // timestamp clock. We do so slowly, because our dispatch_queue seems to give us
        // callbacks in some time-slotted fashion.
        epoch += (delta/10);
        //NSLog(@"AudioInput: clock: delta %lld us, epoch set to %lld uS", delta, epoch);
    }

    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    OSType format = CMFormatDescriptionGetMediaSubType(formatDescription);
	assert(format == kAudioFormatLinearPCM);
    
	CMBlockBufferRef bufferOut = nil;
    size_t bufferListSizeNeeded = 0;
    AudioBufferList *bufferList = NULL;
	OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, &bufferListSizeNeeded, NULL, 0, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
    if (err == 0) {
        bufferList = malloc(bufferListSizeNeeded);
        err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, bufferList, bufferListSizeNeeded, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
    }
    if (err == 0 && bufferList[0].mNumberBuffers == 1) {
		// Pass to the manager
		[self.manager newInputDone: bufferList[0].mBuffers[0].mData size: bufferList[0].mBuffers[0].mDataByteSize channels: bufferList[0].mBuffers[0].mNumberChannels at: [self now]];
	} else {
		NSLog(@"AudioInput: CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer returned err=%d, mNumberBuffers=%d", (int)err, (unsigned int)(bufferList?bufferList[0].mNumberBuffers:-1));
	}
	if (bufferOut) CFRelease(bufferOut);
    if (bufferList) free(bufferList);
}

@end
