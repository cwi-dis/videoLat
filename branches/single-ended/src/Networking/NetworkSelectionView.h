//
//  NetworkSelectionView.h
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>
#import "NetworkInput.h"

///
/// Subclass of NSView that may at some point allow user to select networking
/// parameters
///
@interface NetworkSelectionView : NSView <NetworkViewProtocol>

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us;
- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us;

@end
