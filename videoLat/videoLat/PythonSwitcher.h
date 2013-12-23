//
//  PythonRunner.h
//  macMeasurements
//
//  Created by Jack Jansen on 31-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VideoRunManager.h"
#include <Python.h>

@interface PythonSwitcher : NSObject  {
	PyObject *dict;
	NSString *script;
    bool hasInput;
}

@property(readonly) NSString *script;
@property(readonly) bool hasInput;
- (PythonSwitcher*)initWithScript: (NSString *)theScript;
- (NSString*)newOutput: (NSString*)data;
- (void)newBWOutput: (bool)isWhite;
- (bool)inputBW;

@end
