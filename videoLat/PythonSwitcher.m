//
//  PythonRunner.m
//  macMeasurements
//
//  Created by Jack Jansen on 31-08-10.
//  Copyright 2010 Centrum voor Wiskunde en Informatica. All rights reserved.
//

#import "PythonSwitcher.h"

@implementation PythonSwitcher

@synthesize script;
@synthesize hasInput;

- (PythonSwitcher*)initWithScript: (NSString *)theScript
{
	self = [super init];
	script = [theScript retain];
	dict = NULL;
 //   Py_SetPythonHome("/System/Library/Frameworks/Python.framework/Versions/2.6/");
	Py_Initialize();
    NSLog(@"Python home=%s\n", Py_GetPythonHome());
    
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *path = [bundle pathForResource:script ofType:nil];
	if (!path) {
		NSString *msg = [NSString stringWithFormat: @"Cannot find script \"%@\".", script];
		NSRunAlertPanel(@"PythonRunner", msg, nil, nil, nil);
		return nil;
	}
	const char *cPath = [path UTF8String];
	FILE *fp = fopen(cPath, "r");

	PyObject *m = PyImport_ImportModule("__main__");
	if (m == NULL)
		Py_FatalError("can't create __main__ module");
	dict = PyModule_GetDict(m);
	assert(dict);
	int rv = PyRun_SimpleFile(fp, cPath);
	fclose(fp);
	if (rv < 0) {
		PyErr_Print();
		NSString *msg = [NSString stringWithFormat: @"Cannot run script \"%@\".", script];
		NSRunAlertPanel(@"PythonRunner", msg, nil, nil, nil);
		return nil;
	}
    PyObject *input = PyObject_GetAttrString(m, "inputBW");
    PyErr_Clear();
    hasInput = (input != NULL);
	return self;
}

- (void)dealloc
{
	Py_Finalize();
	[super dealloc];
}

- (NSString*)newOutput: (NSString*)data
{
	if (dict == NULL) return NULL;
	NSLog(@"newOutput: %@\n", data);
	NSString *cmd = [NSString stringWithFormat: @"newOutput(\"%@\")", data];
	PyObject *rv = PyRun_String([cmd UTF8String], Py_eval_input, dict, dict);
	if (rv == NULL) {
		PyErr_Print();
		NSRunAlertPanel(@"PythonRunner", @"newOutput() ended with an exception. Python code disabled.", nil, nil, nil);
		dict = NULL;
		return nil;
	}
	if (rv == Py_None)
		return nil;
	char *rvStr = PyString_AsString(rv);
	if (rvStr == 0) {
		NSRunAlertPanel(@"PythonRunner", @"newOutput() should return a string or None.", nil, nil, nil);
		Py_DECREF(rv);
		return nil;
	}
	NSString *rvNS = [NSString stringWithUTF8String:rvStr];
	Py_DECREF(rv);
	return rvNS;
}

- (void)newBWOutput: (bool)isWhite
{
	NSLog(@"newBWOutput: %d\n", isWhite);
	if (dict == NULL) return;
	NSString *cmd = [NSString stringWithFormat: @"newBWOutput(\"%d\")", isWhite];
	PyObject *rv = PyRun_String([cmd UTF8String], Py_eval_input, dict, dict);
	if (rv == NULL) {
		PyErr_Print();
		NSRunAlertPanel(@"PythonRunner", @"newBWOutput() ended with an exception. Python code disabled.", nil, nil, nil);
		dict = NULL;
		return;
	}
	Py_DECREF(rv);
}

- (bool)inputBW
{
    if (dict == NULL) return;
    PyObject *prv = PyRun_String("inputBW()", Py_eval_input, dict, dict);
	if (prv == NULL) {
		PyErr_Print();
		NSRunAlertPanel(@"PythonRunner", @"inputBW() ended with an exception. Python code disabled.", nil, nil, nil);
		dict = NULL;
		return;
	}
    bool rv = PyObject_IsTrue(prv);
    Py_DECREF(prv);
    return rv;
}

@end
