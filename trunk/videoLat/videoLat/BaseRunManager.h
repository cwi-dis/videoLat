//
//  BaseRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"

@interface BaseRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
    NSString *_measurementTypeName;
}

+ (void)initialize;
+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name;
+ (Class)classForMeasurementType: (NSString *)name;
+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name;
+ (NSString *)nibForMeasurementType: (NSString *)name;

@property(readonly) NSString *measurementTypeName;

- (void)selectMeasurementType: (NSString *)typeName;

@end
