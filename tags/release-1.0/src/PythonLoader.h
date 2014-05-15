//
//  PythonLoader.h
//  videoLat
//
//  Created by Jack Jansen on 21/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Foundation/Foundation.h>

@interface PythonLoader : NSObject
+ (PythonLoader *)sharedPythonLoader;

- (PythonLoader *)init;

- (BOOL)loadURL: (NSURL *)script;
- (BOOL)loadScriptNamed: (NSString *)name;
@end
