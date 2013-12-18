//
//  BaseRunManager.h
//  videoLat
//
//  Created by Jack Jansen on 24/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocols.h"
#import "MeasurementType.h"
#import "RunCollector.h"

@interface BaseRunManager : NSObject <RunOutputManagerProtocol, RunInputManagerProtocol> {
    MeasurementType *measurementType;
}

+ (void)initialize;
+ (void)registerClass: (Class)managerClass forMeasurementType: (NSString *)name;
+ (Class)classForMeasurementType: (NSString *)name;
+ (void)registerNib: (NSString*)nibName forMeasurementType: (NSString *)name;
+ (NSString *)nibForMeasurementType: (NSString *)name;

@property(readonly) MeasurementType *measurementType;

- (void)selectMeasurementType: (NSString *)typeName;

@property bool running;
@property bool preRunning;

@property(weak) IBOutlet RunCollector *collector;

@end
