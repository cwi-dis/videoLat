//
//  MeasurementType.h
//  videoLat
//
//  Created by Jack Jansen on 21/11/13.
//  Copyright (c) 2013 CWI. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MeasurementType : NSObject {
    NSUInteger _tag;
    NSString *_name;
    BOOL _isCalibration;
    MeasurementType *_requires;
}

+ (MeasurementType *)withName: (NSString *)name;
+ (MeasurementType *)withTag: (NSUInteger)tag;
+ (MeasurementType *)add: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req;
+ initialize;

- (void)initWithName: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req;

@property(readonly) NSUInteger tag;
@property(readonly) NSString *name;
@property(readonly) BOOL isCalibration;
@property(readonly) MeasurementType *requires;

@end
