//
//  findQRcodesCI.h
//  videoLat-iOS
//
//  Created by Jack Jansen on 30/04/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"

@interface FindQRcodesCI : NSObject <InputVideoFindProtocol> {
	CIDetector *detector;
	NSString *lastDetection;
}

@property(readonly) NSorUIRect rect;	//!< Rectangle around most recent QR code found

- (NSString *) find: (CVImageBufferRef)image;

@end
