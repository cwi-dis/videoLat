//
//  AudioProcess.h
//  videoLat
//
//  Created by Jack Jansen on 16/04/14.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>

///
/// Object that does pattern-matching on audio data to compare it to a known audio sample.
///
/// The current implementation is very simple-minded: it looks for a bit of noise in an otherwise
/// quiet sample.
///
@interface AudioProcess : NSObject {
	BOOL wasNoisy;				//!< true if the previous buffer ended noisily
	double prevEnergy;			//!< amount of energy in previous buffer
	uint64_t matchTimestamp;	//!< timestamp of most recent match
}

@property(retain) NSArray *originalSignature;

- (AudioProcess *)clone;
///
/// Primes the audio processor to detect copies of this sample.
/// @param fileURL File containing original audio sample
/// @return the signature of the audio file.
///
- (NSArray *)processOriginal: (NSURL *) fileURL;
///
/// Feed audio data into the matcher.
/// @param buffer memory buffer containing audio data (16 bit signed linear PCM)
/// @param size size of buffer, in bytes
/// @param channels number of channels (can be 1 or 2)
/// @param now timestamp corresponding to first sample in buffer
/// @return true if a copy of sample fed into processOriginal has been found (either now or earlier).
/// Once this method returns true you can use lastMatchTimestamp to obtain the timestamp of the
/// match.
///
- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels bitsPerChannel: (int)nBits at: (uint64_t)now duration: (uint64_t)duration;
///
/// Timestamp (in feedData terms) of match that corresponds to the beginning of
/// the sample fed to processOriginal.
///
- (uint64_t) lastMatchTimestamp;

- (void)_reset;	//!< Internal: reset internal variables to prepare for new match
@end

