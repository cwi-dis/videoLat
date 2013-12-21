//
//  PythonLoader.m
//  videoLat
//
//  Created by Jack Jansen on 21/12/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "PythonLoader.h"
#import <Python.h>

@implementation PythonLoader

static PythonLoader *theSharedPythonLoader;

+ (PythonLoader *)sharedPythonLoader
{
    if (theSharedPythonLoader == nil) {
        theSharedPythonLoader = [[PythonLoader alloc] init];
    }
    return theSharedPythonLoader;
}

- (PythonLoader *)init
{
    self = [super init];
    if (self) {
		Py_Initialize();
		NSLog(@"Python home=%s\n", Py_GetPythonHome());
		
    }
    return self;
}

- (BOOL)loadURL: (NSURL *)script
{
    BOOL rv = NO;
    PyObject *pDir = NULL, *sys = NULL, *sysPath = NULL, *prv = NULL;
    
    // XXX Threading
    // Get script path and containing directory path in C strings.
    char cScript[1024];
    if (![script getFileSystemRepresentation:cScript maxLength:sizeof(cScript)])
        return NO;
    NSURL *dir = [script URLByDeletingLastPathComponent];
    char cDir[1024];
    if (![dir getFileSystemRepresentation:cDir maxLength:sizeof(cDir)])
        return NO;
    pDir = PyString_InternFromString(cDir);
    if (pDir == NULL) goto bad;
    
    
    // Add directory path to sys.path
    sys = PyImport_ImportModule("sys");
    if (sys == NULL) goto bad;
    sysPath = PyObject_GetAttrString(sys, "path");
    if (sysPath == NULL) goto bad;
    if (!PySequence_Contains(sysPath, pDir)) {
        prv = PyObject_CallMethod(sysPath, "insert", "iO", 0, sysPath);
        if (prv == NULL) goto bad;
        Py_DECREF(prv);
    }
    
    // Import script
    FILE *fp = fopen(cScript, "r");
    if (fp == NULL) goto bad;
    int rsvReturn = PyRun_SimpleFile(fp, cScript);
    fclose(fp);
    if (rsvReturn >= 0)
        rv = YES;

bad:
    Py_DECREF(prv);
    Py_XDECREF(sysPath);
    Py_XDECREF(sys);
    Py_XDECREF(pDir);
    return rv;
}

- (BOOL)loadScriptNamed: (NSString *)name
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:name withExtension: @".py"];
    return [self loadURL: url];
}
@end
