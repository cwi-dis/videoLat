//
//  MeasurementType.h
//  videoLat
//
//  Created by Jack Jansen on 21/11/13.
//  Copyright 2010-2014 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import <Cocoa/Cocoa.h>
#import "MeasurementDataStore.h"

@interface MeasurementType : NSObject {
	NSMutableDictionary *measurements;
}

+ (MeasurementType *)forType: (NSString *)name;
+ (MeasurementType *)forTag: (NSUInteger)tag;
+ (MeasurementType *)addType: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req;
+ (void)initialize;

- (MeasurementType *)initWithType: (NSString *)_name tag: (NSUInteger)_tag isCalibration: (BOOL)_isCalibration requires: (MeasurementType *)_requires;
- (void)addMeasurement: (MeasurementDataStore *)item;
- (MeasurementDataStore *)measurementNamed: (NSString *)name;
- (NSArray *)measurementNames;
- (NSArray *)measurementNamesForType: (NSString *)typeName;

@property(readonly) NSUInteger tag;
@property(readonly) NSString *name;
@property(readonly) BOOL isCalibration;
@property(readonly) MeasurementType *requires;

@end
