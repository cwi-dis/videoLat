//
//  BaseRunManager.m
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import "BaseRunManager.h"

static NSMutableDictionary *runManagerClasses;

@implementation BaseRunManager

+ (void)initialize
{
    runManagerClasses = [[NSMutableDictionary alloc] initWithCapacity:10];
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

@synthesize measurementTypeName;

- (void) selectMeasurementType:(NSString *)typeName
{
	measurementTypeName = typeName;
}
@end
