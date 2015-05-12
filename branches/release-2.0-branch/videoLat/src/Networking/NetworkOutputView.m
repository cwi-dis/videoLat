//
//  NetworkOutputView.m
//  videoLat
//
//  Created by Jack Jansen on 7/01/14.
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "NetworkOutputView.h"

@implementation NetworkOutputView
- (NSString *)deviceID
{
	return @"NetworkOutput";
}

- (NSString *)deviceName
{
	return @"NetworkOutput";
}

- (void) showNewData
{
}


- (void) reportClient: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportClient ip=%@ port=%d isUs=%d", ip, port, us);
}

- (void) reportServer: (NSString *)ip port: (int)port isUs: (BOOL) us
{
    NSLog(@"NetworkSelectionView.reportServer ip=%@ port=%d isUs=%d", ip, port, us);
}

@end
