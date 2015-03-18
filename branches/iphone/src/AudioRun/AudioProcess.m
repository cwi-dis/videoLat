//
//  AudioProcess
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "AudioProcess.h"
#import <AVFoundation/AVFoundation.h>

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
	prevEnergy = 999999;
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
            size_t chunkRemaining = bufferList[0].mBuffers[0].mDataByteSize;
            int numChannels = bufferList[0].mBuffers[0].mNumberChannels;
            do {
                size_t chunkSize = nSampleToFeed*sampleSize*numChannels;
                if (chunkSize > chunkRemaining) chunkSize = chunkRemaining;
                BOOL noisy = [self feedData: chunkBuffer size: chunkSize channels: numChannels bitsPerChannel: sampleSize*8 at: timestamp];
                if (VL_DEBUG) NSLog(@"timestamp %lld noisy %d", timestamp, noisy);
                if (noisy) [rv addObject: [NSNumber numberWithLongLong:(long long)timestamp]];
                chunkRemaining -= chunkSize;
                chunkBuffer += chunkSize;
                timestamp += (UInt64)((Float64)(nSampleToFeed / sampleRate) * 1000000.0); // May overshoot, but only at end-of-buffer
            } while (chunkRemaining > 0);
        } else {
            NSLog(@"AudioInput: CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer returned err=%d, mNumberBuffers=%d", (int)err, (unsigned int)(bufferList?bufferList[0].mNumberBuffers:-1));
            rv = nil;
        }
        if (bufferOut) CFRelease(bufferOut);
        if (bufferList) free(bufferList);
    }
    [fileReader cancelReading];
    // Prepare for normal feedData input:
    [self _reset];
    return rv;
}

- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels bitsPerChannel: (int)nBits at: (uint64_t)now
{
	double energy = 0;
    if (nBits == 16) {
        SInt16 *sBuffer = (SInt16 *)buffer;
        size_t n = size / sizeof(short);
        for (int i=0; i < n; i++) {
            energy += sBuffer[i]*sBuffer[i];
        }
        energy /= n;
    } else if (1 && nBits == 32) { // Hack: floating point numbers
        float *lBuffer = (float *)buffer;
        size_t n = size / sizeof(long);
        for (int i=0; i < n; i++) {
            float fval = lBuffer[i];
            short sval = (short)(fval*32767);
            energy += sval*sval;
        }
        energy /= n;
    } else if (nBits == 32) {
        SInt32 *lBuffer = (SInt32 *)buffer;
        size_t n = size / sizeof(long);
        for (int i=0; i < n; i++) {
            long lval = lBuffer[i];
            short sval = (short)(lval >> 16);
            energy += sval*sval;
        }
        energy /= n;
    } else {
        assert(0);
    }
    
	//NSLog(@"energy=%f, prevEnergy=%f, bits=%d", energy, prevEnergy, nBits);
	if (wasNoisy) {
		// If we were noisy before we'll still consider it noisy
		// if we're over 75% of what we had
		wasNoisy = (energy > 1 + 0.5 * prevEnergy);
		prevEnergy = (3*energy + prevEnergy) / 4;
	} else {
		// If we were quiet we want at least twice the noise
		wasNoisy = (energy > 1 + 4 * prevEnergy);
		prevEnergy = energy;
		matchTimestamp = now;
	}
	return wasNoisy;
}

- (uint64_t) lastMatchTimestamp
{
    assert(self.originalSignature);
    assert([self.originalSignature count] >= 1);
    NSNumber *originalOnset = [self.originalSignature objectAtIndex:0];
    return matchTimestamp - [originalOnset longLongValue];
}

@end
