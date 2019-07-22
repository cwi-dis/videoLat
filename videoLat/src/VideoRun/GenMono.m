//
//  GenMono.m
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "GenMono.h"


@implementation GenMono
- (GenMono*)init
{
    self = [super init];
    qrcodegenerator = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrcodegenerator setValue: @"M" forKey:@"inputCorrectionLevel"];
    return self;
}


- (CIImage *) genImageForCode: (NSString *)code size:(int)size
{
    CIImage *newImage;
    if ([code isEqualToString: @"white"]) {
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:1 green:1 blue:1]];
    } else if ([code isEqualToString: @"black"]) {
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0]];
    } else {
        // Image with a random grey level
        double outputLevel = (double)rand() / (double)RAND_MAX;
        newImage = [CIImage imageWithColor:[CIColor colorWithRed:outputLevel green:outputLevel blue:outputLevel]];
    }
    CGRect rect = {0, 0, 1, 1};
    newImage = [newImage imageByCroppingToRect: rect];
    return newImage;
}
@end
