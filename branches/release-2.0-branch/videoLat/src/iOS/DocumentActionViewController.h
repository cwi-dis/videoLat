///
///  @file DocumentActionViewController.h
///  @brief Holds definition of DocumentActionViewController object.
//
//  Copyright 2010-2015 Centrum voor Wiskunde en Informatica. Licensed under GPL3.
//
//

#import <UIKit/UIKit.h>
#import "Document.h"

///
/// View controller for operations on documents.
///
@interface DocumentActionViewController : UIViewController
@property(weak) Document *document;
@property(weak) IBOutlet UIButton *bPrint;
@property(weak) IBOutlet UIButton *bUpload;

@end
