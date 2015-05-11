//
//  NetworkSelectionView.m
//  videoLat
//
//  Created by Jack Jansen on 18/11/13.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkSelectionView.h"
@implementation NetworkSelectionView
@dynamic bBase;
#ifdef WITH_APPKIT
@dynamic bDevices;
@dynamic bPreRun;
#endif

- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportClient ip=%@ port=%d isUs=%d", ip, port, us);
}

- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportServer ip=%@ port=%d isUs=%d", ip, port, us);
}

@end
