//
//  AudioProcess.h
//  videoLat
//
//  Created by Jack Jansen on 16/04/14.
//  Copyright (c) 2014 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioProcess : NSObject {
	BOOL wasNoisy;
	float prevEnergy;
	uint64_t matchTimestamp;
}

- (NSArray *)processOriginal: (NSURL *) fileURL;
- (BOOL)feedData: (void *)buffer size: (size_t)size channels: (int)channels at: (uint64_t)now;
- (uint64_t) lastMatchTimestamp;

- (void)_reset;
@end

