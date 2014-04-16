//
//  HardwareRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 22/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "AudioProcess.h"

@implementation AudioProcess

- (AudioProcess *) init
{
	self = [super init];
	wasNoisy = NO;
	prevEnergy = 999999;
	matchTimestamp = 0;
	return self;
}

- (void)setOriginal: (NSString *) fileName
{
}

- (BOOL)feedData: (void *)buffer size: (size_t)size at: (uint64_t)now
{
	short *fBuffer = (short *)buffer;
	float energy = 0;
	int n = size / sizeof(short);
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
