///
///  @file findMono.h
///  @brief Detect monochrome colors in video using CoreImage.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "protocols.h"

@interface FindMono : NSObject <InputVideoFindProtocol> {
    NSorUIRect sensitiveArea;       //!< Internal: where we look for black/white in the input signal.
    int minInputLevel;             //!< Internal: darkest color seen during prerun
    int maxInputLevel;             //!< Internal: lightest color seen during prerun
}

@property(readonly) NSorUIRect rect;	//!< Rectangle around most recent QR code found

- (NSString *) find: (CVImageBufferRef)image;

@end
