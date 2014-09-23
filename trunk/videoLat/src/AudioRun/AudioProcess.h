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
	BOOL wasNoisy;				//!< Internal: true if the previous buffer ended noisily
	float prevEnergy;			//!< Internal: amount of energy in previous buffer
	uint64_t matchTimestamp;	//!< Internal: timestamp of most recent match
}

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
/// @return true if a copy of sample fed into @see processOriginal has been found (either now or earlier).
/// Once this method returns true you can use @see lastMatchTimestamp to obtain the timestamp of the
/// match.
///
- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels at: (uint64_t)now;
///
/// Timestamp (in @see feedData terms) of match that corresponds to the beginning of
/// the sample fed to @see processOriginal.
///
- (uint64_t) lastMatchTimestamp;

- (void)_reset;	//!< Internal: reset internal variables to prepare for new match
@end

