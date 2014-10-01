///
///  @file PythonLoader.h
///  @brief Holds PythonLoader object definition.
//
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <Foundation/Foundation.h>

///
/// Load Python code.
/// Because the Python code runs in the same binary as videoLat it has access to all
/// the objects in the program, through the pyobjc pytho<->ObjC bridge.
/// For an example, see @see LabJackDevice which implements the @see HardwareLightProtocol
/// and can then be instantiate in the NIB file and connected to the right objects.
///
@interface PythonLoader : NSObject
+ (PythonLoader *)sharedPythonLoader;	//!< Singleton pattern

- (PythonLoader *)init;	//!< Internal: initialize the loader object

///
/// Load a Python script.
/// @param script the URL of the script to load (must be a local file)
/// @return true if successful
///

- (BOOL)loadURL: (NSURL *)script;
///
/// Load a Python script from a named resource.
/// @param name the name of the script
/// @return true if successful
///
- (BOOL)loadScriptNamed: (NSString *)name;
@end
