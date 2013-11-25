//
//  BaseRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "BaseRunManager.h"

static NSMutableDictionary *runManagerClasses;
static NSMutableDictionary *runManagerNibs;

@implementation BaseRunManager

+ (void)initialize
{
    runManagerClasses = [[NSMutableDictionary alloc] initWithCapacity:10];
    runManagerNibs = [[NSMutableDictionary alloc] initWithCapacity:10];
}

+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name
{
    // XXXJACK assert it is a subclass of BaseRunManager
    Class oldClass = [runManagerClasses objectForKey:name];
    if (oldClass != nil && oldClass != managerClass) {
        NSLog(@"BaseRunManager: attempt to set class for %@ to %@ but ist was already set to %@\n", name, managerClass, oldClass);
        abort();
    }
    NSLog(@"BaseRunManager: Register %@ for %@\n", managerClass, name);
    [runManagerClasses setObject:managerClass forKey:name];
}

+ (Class)classForMeasurementType: (NSString *)name
{
    return [runManagerClasses objectForKey:name];
}

+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name
{
    // XXXJACK assert it is a subclass of BaseRunManager
    NSString *oldNib = [runManagerNibs objectForKey:name];
    if (oldNib != nil && oldNib != nibName) {
        NSLog(@"BaseRunManager: attempt to set Nib for %@ to %@ but it was already set to %@\n", name, nibName, oldNib);
        abort();
    }
    NSLog(@"BaseRunManager: Register %@ for %@\n", nibName, name);
    [runManagerNibs setObject:nibName forKey:name];
}

+ (NSString *)nibForMeasurementType: (NSString *)name
{
    return [runManagerNibs objectForKey:name];
}

@synthesize measurementTypeName;

- (void) selectMeasurementType:(NSString *)typeName
{
	measurementTypeName = typeName;
}


- (CIImage *)newOutputStart
{
	[NSException raise:@"BaseRunManager" format:@"Must override newOutputStart in subclass"];
	return nil;
}

- (void)newOutputDone
{
	[NSException raise:@"BaseRunManager" format:@"Must override newOutputDone in subclass"];
}


- (void)updateOutputOverhead: (double)deltaT
{
	[NSException raise:@"BaseRunManager" format:@"Must override updateOutputOverhead in subclass"];
}

- (void)reportDataCapturer: (id)capturer
{
	[NSException raise:@"BaseRunManager" format:@"Must override reportDataCapturer in subclass"];
}


- (void)setFinderRect: (NSRect)theRect
{
	[NSException raise:@"BaseRunManager" format:@"Must override setFinderRect in subclass"];
}


- (void)newInputStart
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputStart in subclass"];
}


- (void)updateInputOverhead: (double)deltaT
{
	[NSException raise:@"BaseRunManager" format:@"Must override updateInputOverhead in subclass"];
}


- (void)newInputDone
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone in subclass"];
}


- (void) newInputDone: (void*)buffer
    width: (int)w
    height: (int)h
    format: (const char*)formatStr
    size: (int)size
{
	[NSException raise:@"BaseRunManager" format:@"Must override newInputDone in subclass"];
}




@end
