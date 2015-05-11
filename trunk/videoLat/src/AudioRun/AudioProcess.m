//
//  AudioProcess
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "AudioProcess.h"
#import <AVFoundation/AVFoundation.h>

#define MAX_FEED_DURATION 10000

@implementation AudioProcess

@synthesize originalSignature;

- (void)dealloc
{
}

- (AudioProcess *) init
{
	self = [super init];
    [self _reset];
	return self;
}

- (AudioProcess *) clone
{
    return [[[self class] alloc] init];
}

- (void)_reset
{
    wasNoisy = NO;
	prevEnergy = 2.0; // Impossible value, will lead to initialization using the first measurement.
	matchTimestamp = 0;
}

- (NSArray *)processOriginal: (NSURL *) fileURL
{
    NSMutableArray *rv = [[NSMutableArray alloc] initWithCapacity:10];
    if (VL_DEBUG) NSLog(@"Processing in setOriginal: %@", fileURL);
    [self _reset];
    // Create an ASSetReader for our input file
    AVURLAsset *fileAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    NSError *error = nil;
    AVAssetReader *fileReader = [AVAssetReader assetReaderWithAsset:fileAsset error:&error];
    
    // Create the readerOutput object from which we can get the samples as they are read
    AVAssetReaderOutput *fileOutput = [AVAssetReaderAudioMixOutput
                                       assetReaderAudioMixOutputWithAudioTracks:fileAsset.tracks
                                       audioSettings: nil];
    if (! [fileReader canAddOutput: fileOutput]) {
        NSLog (@"can't add reader output... die!");
        return nil;
    }
    [fileReader addOutput: fileOutput];
    
    // Start reading
    [fileReader startReading];
    
    // Process the data
    CMSampleBufferRef sampleBuffer;
    while(1) {
        sampleBuffer = [fileOutput copyNextSampleBuffer];
        if (sampleBuffer == NULL) break;
        assert(CMSampleBufferDataIsReady(sampleBuffer));

        CMTime durationCMT = CMSampleBufferGetDuration(sampleBuffer);
        durationCMT = CMTimeConvertScale(durationCMT, 1000000, kCMTimeRoundingMethod_Default);
        UInt64 duration = durationCMT.value;

        CMTime timestampCMT = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
        UInt64 timestamp = timestampCMT.value;

        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        assert(formatDescription);
        OSType format = CMFormatDescriptionGetMediaSubType(formatDescription);
        assert(format == kAudioFormatLinearPCM);
        const AudioStreamBasicDescription* const basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        Float64 sampleRate = basicDescription->mSampleRate;
        int sampleSize = basicDescription->mBitsPerChannel / 8;
        assert(basicDescription->mBitsPerChannel == sampleSize * 8);
        int nSampleToFeed = 1024;

        CMBlockBufferRef bufferOut = nil;
        size_t bufferListSizeNeeded = 0;
        AudioBufferList *bufferList = NULL;
        OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, &bufferListSizeNeeded, NULL, 0, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
        if (err == 0) {
            bufferList = malloc(bufferListSizeNeeded);
            err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, bufferList, bufferListSizeNeeded, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
        }
        if (err == 0 && bufferList[0].mNumberBuffers == 1) {
            // Pass to the manager in chunks of 1K samples.
            // XXXJACK Note that the 1K is temporary, it happens to be what the input processor does
            void *chunkBuffer = bufferList[0].mBuffers[0].mData;
            size_t chunkTotalSize = bufferList[0].mBuffers[0].mDataByteSize;
            size_t chunkRemaining = chunkTotalSize;
            int numChannels = bufferList[0].mBuffers[0].mNumberChannels;
            do {
                size_t chunkSize = nSampleToFeed*sampleSize*numChannels;
                if (chunkSize > chunkRemaining) chunkSize = chunkRemaining;
				UInt64 chunkDuration = (chunkSize * duration) / chunkTotalSize;
                BOOL noisy = [self feedData: chunkBuffer
								   size: chunkSize
								   channels: numChannels
								   bitsPerChannel: sampleSize*8
								   at: timestamp
								   duration: chunkDuration];
                if (VL_DEBUG) NSLog(@"timestamp %lld noisy %d", timestamp, noisy);
                if (noisy)
					[rv addObject: [NSNumber numberWithLongLong:(long long)timestamp]];
                chunkRemaining -= chunkSize;
                chunkBuffer += chunkSize;
                timestamp += (UInt64)((Float64)(nSampleToFeed / sampleRate) * 1000000.0); // May overshoot, but only at end-of-buffer
            } while (chunkRemaining > 0);
        } else {
            NSLog(@"AudioInput: CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer returned err=%d, mNumberBuffers=%d", (int)err, (unsigned int)(bufferList?bufferList[0].mNumberBuffers:-1));
            rv = nil;
            rv = nil;
            rv = nil;
        }
        if (bufferOut) CFRelease(bufferOut);
        if (bufferList) free(bufferList);
    }
    [fileReader cancelReading];
    // Prepare for normal feedData input:
    [self _reset];
	assert(rv);
	assert([rv count]);
    return rv;
}

- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels bitsPerChannel: (int)nBits at: (uint64_t)now duration: (uint64_t)duration
{
	if (duration > MAX_FEED_DURATION) {
		if (VL_DEBUG) NSLog(@"feedData recurse");
		size_t halfSize = size/2;
		halfSize -= (halfSize % (channels * nBits / 8));
		uint64_t halfDuration = duration / 2;
		BOOL rv1 = [self feedData:buffer size:halfSize channels:channels bitsPerChannel:nBits at:now duration:halfDuration];
		BOOL rv2 = [self feedData:buffer+halfSize size:size-halfSize channels:channels bitsPerChannel:nBits at:now+halfDuration duration:halfDuration];
		return rv1 || rv2;
	}
	if (VL_DEBUG) NSLog(@"feedData duration=%lld µS", duration);
	double energy = 0;
    if (nBits == 16) {
        SInt16 *sBuffer = (SInt16 *)buffer;
        size_t n = size / sizeof(short);
		assert(n*sizeof(short) == size);
        for (int i=0; i < n; i++) {
			SInt16 sval = sBuffer[i];
            energy += (double)abs(sval) / 32768.0;
        }
        energy /= n;
    } else if (1 && nBits == 32) { // Hack: floating point numbers
        float *lBuffer = (float *)buffer;
        size_t n = size / sizeof(float);
		assert(n*sizeof(float) == size);
        for (int i=0; i < n; i++) {
            float fval = lBuffer[i];
            energy += fabs(fval);
        }
        energy /= n;
    } else if (nBits == 32) {
        SInt32 *lBuffer = (SInt32 *)buffer;
        size_t n = size / sizeof(long);
		assert(n*sizeof(long) == size);
        for (int i=0; i < n; i++) {
            long lval = lBuffer[i];
            short sval = (short)(lval >> 16);
            energy += (double)abs(sval) / 32768.0;
        }
        energy /= n;
    } else {
        assert(0);
    }
    
	if (VL_DEBUG) NSLog(@"energy=%f, prevEnergy=%f, bits=%d", energy, prevEnergy, nBits);
	BOOL isNoisy;
	if (prevEnergy > 1) {
		isNoisy = NO;
		wasNoisy = NO;
		prevEnergy = energy;
	} else if (wasNoisy) {
		// If we were noisy before we'll still consider it noisy
		// if we're over 75% of what we had
		isNoisy = (energy > 0.01 + 0.5 * prevEnergy);
		prevEnergy = (3*energy + prevEnergy) / 4;
	} else {
		// If we were quiet we want at least twice the noise
		isNoisy = (energy > 0.01 + 4 * prevEnergy);
		prevEnergy = (3*energy + prevEnergy) / 4;
	}
	if (isNoisy && !wasNoisy) {
		matchTimestamp = now;
	}
	wasNoisy = isNoisy;
	return isNoisy;
}

- (uint64_t) lastMatchTimestamp
{
    assert(self.originalSignature);
    assert([self.originalSignature count] >= 1);
    NSNumber *originalOnset = [self.originalSignature objectAtIndex:0];
    return matchTimestamp - [originalOnset longLongValue];
}

@end
