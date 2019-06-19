///
///  @file MeasurementType.h
///  @brief Definition of MeasurementType object.
//
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import "MeasurementDataStore.h"
#import "protocols.h"

///
/// Class to store measurements of a given type.
///
/// The class methods maintain all known measurement types, and allow retrieving these by
/// name or tag (for the menus).
///
/// Individual objects contain  dependencies (such as video measurements depending on video calibration measurements),
/// and for the calibration measurements they also store all instances of masurement runs for that
/// specific type that have been done previously (initialized by the appDelegate).
///
@interface MeasurementType : NSObject<MeasurementTypeProtocol> {
	NSMutableDictionary *measurements;	//!< All measurements of this type, indexed by name.
    MeasurementType *superType;         //!< Pointer to generalization of this measurement type (if there is one).
}

+ (void)initialize; //!< Class initializer, populates class with implemented measurement types.

+ (MeasurementType *)addType: (NSString *)name tag: (NSUInteger) tag isCalibration: (BOOL)cal requires: (MeasurementType *)req; //!< Add a new  MeasurementType.
+ (MeasurementType *)forType: (NSString *)name; //!< Returns MeasurementType with the given name.
+ (MeasurementType *)forTag: (NSUInteger)tag; //!< Returns MeasurementType with the given name.

- (MeasurementType *)initWithType: (NSString *)_name tag: (NSUInteger)_tag isCalibration: (BOOL)_isCalibration requires: (MeasurementType *)_requires; //!< Object initializer.
- (void)addMeasurement: (MeasurementDataStore *)item;   //!< Add a measurement run of this type.
- (MeasurementDataStore *)measurementNamed: (NSString *)name;   //!< Retrieve a measurement run by name.
- (NSArray *)measurementNames;  //!< Return all names for measurements of this type, used for menu population.

@property(readonly) NSUInteger tag;     //!< Tag for this type, used to order measurement types logically in menus.
@property(readonly) NSString *name;     //!< Human-readable type
@property(readonly) BOOL isCalibration; //!< True if this type is a calibration meaurement type
@property BOOL inputOnlyCalibration;    //!< True if only the input should match
@property BOOL outputOnlyCalibration;   //!< True if only the output should match
@property(readonly) MeasurementType *requires;  //!< What this measurement type depends on (usually a calibration) or nil.

@end
