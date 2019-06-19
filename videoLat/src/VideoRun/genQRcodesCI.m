//
//  genQRcodesCI.m
//  macMeasurements
//
//  Created by Jack Jansen on 21-08-10.
//  Copyright 2010-2019 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//

#import "genQRcodesCI.h"


@implementation GenQRcodesCI
- (GenQRcodesCI*)init
{
    self = [super init];
    qrcodegenerator = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrcodegenerator setValue: @"M" forKey:@"inputCorrectionLevel"];
    return self;
}


- (CIImage *) genImageForCode: (NSString *)code size:(int)size;
{
    NSData *codeData = [code dataUsingEncoding:NSUTF8StringEncoding];
    [qrcodegenerator setValue: codeData forKey:@"inputMessage"];
    CIImage *codeImage = qrcodegenerator.outputImage;
    // xxxx convert size
    CGRect imageSize = CGRectIntegral(codeImage.extent); // generated image size
    CGSize outputSize = CGSizeMake(size, size); // required image size
    CIImage *imageByTransform = [codeImage imageByApplyingTransform:CGAffineTransformMakeScale(outputSize.width/CGRectGetWidth(imageSize), outputSize.height/CGRectGetHeight(imageSize))];

    return imageByTransform;

}

- (void)gen:(void *)buffer width:(int)width height:(int)height code:(const char *)code {
    showWarningAlert(@"getQRcodesCI: incorrect generator called");
}
@end
