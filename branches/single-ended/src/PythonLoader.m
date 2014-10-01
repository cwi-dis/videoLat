//
//  PythonLoader.m
//  videoLat
//
//  Created by Jack Jansen on 21/12/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
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
        PyEval_InitThreads();
		Py_Initialize();
		NSLog(@"Python home=%s\n", Py_GetPythonHome());
		PyEval_SaveThread();
    }
    return self;
}

- (BOOL)loadURL: (NSURL *)script
{
    PyGILState_STATE gstate;
    gstate = PyGILState_Ensure();
    NSLog(@"PythonLoader loadURL %@", script);
    BOOL rv = NO;
    NSURL *dir = [script URLByDeletingLastPathComponent];
    PyObject *pDir = NULL, *sys = NULL, *sysPath = NULL, *prv = NULL;
    
#if 0
    // Get script path and containing directory path in C strings.
    char cScript[1024];
    if (![script getFileSystemRepresentation:cScript maxLength:sizeof(cScript)])
        goto bad;
    char cDir[1024];
    if (![dir getFileSystemRepresentation:cDir maxLength:sizeof(cDir)])
        goto bad;
#else
	const char *cScript = [[script path] UTF8String];
	const char *cDir = [[dir path] UTF8String];
#endif
    pDir = PyString_InternFromString(cDir);
    if (pDir == NULL) goto bad;
    
    
    // Add directory path to sys.path
    sys = PyImport_ImportModule("sys");
    if (sys == NULL) goto bad;
    sysPath = PyObject_GetAttrString(sys, "path");
    if (sysPath == NULL) goto bad;
    if (!PySequence_Contains(sysPath, pDir)) {
        prv = PyObject_CallMethod(sysPath, "insert", "iO", 0, pDir);
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
    PyGILState_Release(gstate);
    return rv;
}

- (BOOL)loadScriptNamed: (NSString *)name
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:name withExtension: @"py"];
	if (url == nil) {
		NSLog(@"PythonLoader: cannot find script %@ in resources", name);
		return NO;
	}
    return [self loadURL: url];
}
@end
