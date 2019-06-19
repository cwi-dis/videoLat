//
//  PythonLoader.m
//  videoLat
//
//  Created by Jack Jansen on 21/12/13.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "PythonLoader.h"
#import <Python.h>
#import "AppDelegate.h"

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
		if (VL_DEBUG) NSLog(@"Python home=%s\n", Py_GetPythonHome());
		PyEval_SaveThread();
    }
    return self;
}

- (BOOL)loadURL: (NSURL *)script
{
    PyGILState_STATE gstate;
    gstate = PyGILState_Ensure();
    if (VL_DEBUG) NSLog(@"PythonLoader loadURL %@", script);
    BOOL rv = NO;
    NSURL *dir = [script URLByDeletingLastPathComponent];
    PyObject *pDir = NULL, *sys = NULL, *sysPath = NULL, *prv = NULL;
    

    const char *cScript = [[script path] UTF8String];
    const char *cDir = [[dir path] UTF8String];
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
    Py_XDECREF(prv);
    Py_XDECREF(sysPath);
    Py_XDECREF(sys);
    Py_XDECREF(pDir);
    PyGILState_Release(gstate);
    return rv;
}


- (BOOL)loadModule: (NSString *)module fromDirectory: (NSURL *)directory
{
    PyGILState_STATE gstate;
    gstate = PyGILState_Ensure();
    NSLog(@"PythonLoader loadModule %@ fromDirectory %@", module, directory);
    BOOL rv = NO;
    PyObject *pDir = NULL, *sys = NULL, *sysPath = NULL, *prv = NULL;
    int rsvReturn = 0;
    
    NSString *cmd = [NSString stringWithFormat:@"import %@", module];
    const char *cCmd = [cmd UTF8String];
    
    const char *cDir = [[directory path] UTF8String];
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
    rsvReturn = PyRun_SimpleString(cCmd);
    if (rsvReturn >= 0)
        rv = YES;
    
bad:
    Py_XDECREF(prv);
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

- (BOOL)loadPackageNamed: (NSString *)name
{
    NSURL *url = [(AppDelegate *)[[NSApplication sharedApplication] delegate] hardwareFolder];
    
    if (url == nil) {
        NSLog(@"PythonLoader: cannot find package %@ in resources", name);
        return NO;
    }
    return [self loadModule: name  fromDirectory: url];
}
@end
