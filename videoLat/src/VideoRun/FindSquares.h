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
#import "LevelStatusView.h"

@interface FindSquares : NSObject <InputVideoFindProtocol> {
    CIDetector *detector;   // Detect squares
    CIContext *context;
}

@property(readonly) NSorUIRect rect;	//!< Rectangle around most recent QR code found
@property(weak) IBOutlet LevelStatusView *levelStatusView;  //!< Assigned in NIB: visual feedback on light level detected

- (NSString *) find: (CVImageBufferRef)image;

@end
