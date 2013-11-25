//
//  appDelegate.m
//  videoLat
//
//  Created by Jack Jansen on 22-11-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "appDelegate.h"
#import "VideoRunManager.h"


@implementation appDelegate
@synthesize measurementTypes;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// Fill measurementTypes
	NSURL *url = [self directoryForCalibrations];
	if (url == nil) return;
	[self _loadCalibrationsFrom:url];
    
    // Initialize run manager classes. Should be done differently.
    [VideoRunManager initialize];
    [VideoCalibrationRunManager initialize];
	[VideoMonoRunManager initialize];
	
}
- (NSURL *)directoryForCalibrations
{
	NSError *error;
	NSURL *url = [NSURL URLWithString:@"videoLat"];
	url = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL: url create:YES error:&error ];
	if (url == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	NSLog(@"appsupport is %@\n", url);
	url = [url URLByAppendingPathComponent:@"videoLat" isDirectory:YES];
	BOOL ok = [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
	if (!ok) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return nil;
	}
	NSLog(@"Created %@\n", url);
	return url;
}

- (void)_loadCalibrationsFrom: (NSURL *)directory
{
	NSError *error;
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directory includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
	if (files == nil) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}
	for (NSURL *url in files) {
		NSLog(@"Could load %@\n", url);
	}
}

@end
