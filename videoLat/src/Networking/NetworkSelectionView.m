//
//  NetworkSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkSelectionView.h"
@implementation NetworkSelectionView
#ifdef WITH_APPKIT
@synthesize bBase;
@synthesize bPreRun;
#endif
@synthesize selectionDelegate;

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportClient ip=%@ port=%d isUs=%d", ip, port, us);
}

- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportServer ip=%@ port=%d isUs=%d", ip, port, us);
}


- (NSString *)baseName {
    NSLog(@"networkSelectionView baseName called");
    assert(0);
}

- (NSString *)deviceName {
    NSLog(@"networkSelectionView deviceName called");
    assert(0);
}

@end
