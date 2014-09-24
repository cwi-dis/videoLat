//
//  AudioProcess
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "AudioProcess.h"
#import <AVFoundation/AVFoundation.h>

@implementation AudioProcess


- (void)dealloc
{
}

- (AudioProcess *) init
{
	self = [super init];
    [self _reset];
	return self;
}

- (void)_reset
{
    wasNoisy = NO;
	prevEnergy = 999999;
	matchTimestamp = 0;
}

- (NSArray *)processOriginal: (NSURL *) fileURL
{
    NSLog(@"Processing in setOriginal: %@", fileURL);
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
        CMTime timestampCMT = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        timestampCMT = CMTimeConvertScale(timestampCMT, 1000000, kCMTimeRoundingMethod_Default);
        UInt64 timestamp = timestampCMT.value;
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSType format = CMFormatDescriptionGetMediaSubType(formatDescription);
        assert(format == kAudioFormatLinearPCM);

        CMBlockBufferRef bufferOut = nil;
        size_t bufferListSizeNeeded;
        OSStatus err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, &bufferListSizeNeeded, NULL, 0, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
        AudioBufferList *bufferList = malloc(bufferListSizeNeeded);
        err = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, bufferList, bufferListSizeNeeded, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &bufferOut);
        if (err == 0 || bufferList[0].mNumberBuffers == 1) {
            // Pass to the manager
            BOOL noisy = [self feedData: bufferList[0].mBuffers[0].mData size: bufferList[0].mBuffers[0].mDataByteSize channels: bufferList[0].mBuffers[0].mNumberChannels at: timestamp];
            NSLog(@"timestamp %lld noisy %d", timestamp, noisy);
        } else {
            NSLog(@"AudioInput: CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer returned err=%d, mNumberBuffers=%d", err, bufferList[0].mNumberBuffers);
        }
        if (bufferOut) CFRelease(bufferOut);
        if (bufferList) free(bufferList);
    }
    [fileReader cancelReading];
    // Prepare for normal feedData input:
    [self _reset];
    return nil;
}

- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels at: (uint64_t)now
{
	short *fBuffer = (short *)buffer;
	float energy = 0;
	size_t n = size / sizeof(short);
	for (int i=0; i < n; i++) {
		energy += fBuffer[i]*fBuffer[i];
	}
	energy /= n;
	//NSLog(@"energy=%f, prevEnergy=%f", energy, prevEnergy);
	if (wasNoisy) {
		// If we were noisy before we'll still consider it noisy
		// if we're over 75% of what we had
		wasNoisy = (energy > 0.5 * prevEnergy);
		prevEnergy = (3*energy + prevEnergy) / 4;
	} else {
		// If we were quiet we want at least twice the noise
		wasNoisy = (energy > 4 * prevEnergy);
		prevEnergy = energy;
		matchTimestamp = now;
	}
	return wasNoisy;
}

- (uint64_t) lastMatchTimestamp
{
	return matchTimestamp;
}

@end
