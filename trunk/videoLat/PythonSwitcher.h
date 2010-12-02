//
//  PythonRunner.h
//  macMeasurements
//
//  Created by Jack Jansen on 31-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Manager.h"
#include <Python/Python.h>

@interface PythonSwitcher : NSObject <MyManagerDelegate> {
	PyObject *dict;
	NSString *script;
}

@property(readonly) NSString *script;
- (PythonSwitcher*)initWithScript: (NSString *)theScript;
- (NSString*)newOutput: (NSString*)data;
- (void)newBWOutput: (bool)isWhite;

@end
