//
//  PythonLoader.h
//  videoLat
//
//  Created by Jack Jansen on 21/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PythonLoader : NSObject
+ (PythonLoader *)sharedPythonLoader;

- (PythonLoader *)init;

- (BOOL)loadURL: (NSURL *)script;
- (BOOL)loadScriptNamed: (NSString *)name;
@end
